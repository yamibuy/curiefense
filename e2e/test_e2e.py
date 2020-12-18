#!/usr/bin/env python3

# Python requirements: pytest requests
# install curieconfctl:
# (cd ../curiefense/curieconf/utils ; pip3 install .)
# (cd ../curiefense/curieconf/client ; pip3 install .)
#
# To run this with minikube (does not support IPv6):
# pytest --base-protected-url http://$(minikube ip):30081 --base-conf-url http://$(minikube ip):30000/api/v1/ --base-ui-url http://$(minikube ip):30080 .
#
# To run this with docker-compose:
# Wait until https://github.com/curiefense/curiefense/issues/48 is fixed
# pytest --base-protected-url http://localhost:30081/ --base-conf-url http://localhost:30000/api/v1/ --base-ui-url http://localhost:30080 .

import json
import logging
import pytest
import random
import requests
import string
import subprocess
import time

log = logging.getLogger("e2e")

# --- Helpers ---
TEST_CONFIG_NAME = "master"


class CliHelper():
    def __init__(self, base_url):
        self._base_url = base_url
        self._initial_version_cache = None

    def call(self, args, inputjson=None) -> str:
        logging.info("Calling CLI with arguments: %s", args)
        cmd = ["curieconfctl", "-u", self._base_url, "-o", "json"]
        cmd += args.split(" ")
        indata = None
        if inputjson:
            indata = json.dumps(inputjson).encode("utf-8")
        p = subprocess.run(cmd, shell=False, input=indata, check=True,
                           capture_output=True)
        if p.stdout:
            logging.debug("CLI output: %s", p.stdout)
            try:
                return json.loads(p.stdout.decode("utf-8"))
            except json.JSONDecodeError:
                return p.stdout.decode("utf-8")
        else:
            return []

    def delete_test_config(self):
        self.call("conf delete test")

    def initial_version(self):
        if not self._initial_version_cache:
            versions = self.call("conf list-versions master")
            self._initial_version_cache = versions[-3]["version"]
        return self._initial_version_cache

    def empty_acl(self):
        version = self.initial_version()
        return self.call(f"doc get master aclpolicies --version {version}")

    def revert_and_enable(self, acl=True, waf=True):
        version = self.initial_version()
        self.call(f"conf revert {TEST_CONFIG_NAME} {version}")
        urlmap = self.call(f"doc get {TEST_CONFIG_NAME} urlmaps")
        urlmap[0]["map"][0]["acl_active"] = acl
        urlmap[0]["map"][0]["waf_active"] = waf
        self.call(f"doc update {TEST_CONFIG_NAME} urlmaps /dev/stdin",
                  inputjson=urlmap)

    def publish_and_apply(self):
        buckets = self.call("key get system publishinfo")
        for b in buckets["buckets"]:
            if b["name"] == "prod":
                url = b["url"]
        self.call(f"sync export master {url}")
        time.sleep(12)


@pytest.fixture(scope="session")
def cli(request):
    return CliHelper(request.config.getoption("--base-conf-url"))


class TargetHelper():
    def __init__(self, base_url):
        self._base_url = base_url

    def query(self, path="/", method="GET", headers=None, srcip=None, **kwargs):
        # specifying a path helps spot tests easily in the access log
        if headers is None:
            headers = {}
        if srcip is not None:
            headers['X-Forwarded-For'] = srcip
        res = requests.request(method=method, url=self._base_url + path,
                               headers=headers, **kwargs)
        return res

    def is_reachable(self, path="/", method="GET", headers=None, srcip=None, **kwargs):
        res = self.query(path, method, headers, srcip, **kwargs)
        return res.status_code in [200, 404]


@pytest.fixture(scope="session")
def target(request):
    url = request.config.getoption("--base-protected-url").rstrip("/")
    return TargetHelper(url)


class UIHelper():
    def __init__(self, base_url):
        self._base_url = base_url

    def check_log_pattern(self, pattern):
        data = {
            "statement": ("SELECT Path FROM logs "
                          "ORDER BY StartTime DESC LIMIT 1024"),
            "parameters": []
        }
        res = requests.post(self._base_url + "/logs/api/v1/exec/", json=data)
        for log in res.json():
            if pattern in log[0]:
                return True
        return False


@pytest.fixture(scope="session")
def ui(request):
    url = request.config.getoption("--base-ui-url").rstrip("/")
    return UIHelper(url)


class ACLHelper:
    def __init__(self, cli):
        self._cli = cli

    def set_acl(self, updates: dict):
        acl = self._cli.empty_acl()
        # update acl
        for k, v in updates.items():
            acl[0][k].append(v)
        self._cli.call(f"doc update {TEST_CONFIG_NAME} aclpolicies /dev/stdin",
                       inputjson=acl)

    def reset_and_set_acl(self, updates: dict):
        self._cli.revert_and_enable()
        self.set_acl(updates)
        self._cli.publish_and_apply()


@pytest.fixture(scope="session")
def acl(cli):
    return ACLHelper(cli)


@pytest.fixture(scope="class")
def default_config(cli):
    cli.revert_and_enable()
    cli.publish_and_apply()


@pytest.fixture(scope="session", params=["headers", "cookies", "params"])
def section(request):
    return request.param


# --- Tests ---


class TestLogs:
    def test_logs(self, default_config, cli, target, ui):
        test_pattern = "/test" + "".join([
            random.choice(string.ascii_lowercase) for i in range(20)])
        assert(target.is_reachable(test_pattern))
        time.sleep(1)
        assert ui.check_log_pattern(test_pattern)


class TestACL:
    def test_enforce_deny_all(self, acl, target):
        acl.reset_and_set_acl({"force_deny": "all"})
        assert not target.is_reachable("/deny-all")

    def test_bypass_all(self, acl, target):
        acl.reset_and_set_acl({"deny": "all", "bypass": "all"})
        assert target.is_reachable("/deny-bypass-all")

    def test_allow_bot_all(self, acl, target):
        acl.reset_and_set_acl({"allow_bot": "all"})
        assert not target.is_reachable(
            "/allow_bot-all",
            headers={"Long-Header": "not_alphanum"*1500})
        assert target.is_reachable()

    def test_deny_bot_all(self, acl, target):
        acl.reset_and_set_acl({"deny_bot": "all"})
        res = target.query("/deny_bot-all")
        assert res.status_code == 247
        assert ";;window.rbzns={bereshit:" in res.text

    def test_allow_all(self, acl, target):
        acl.reset_and_set_acl({"allow": "all", "deny": "all"})
        assert not target.is_reachable(
            "/allow-deny-all",
            headers={"Long-Header": "not_alphanum"*1500})
        assert target.is_reachable()

    def test_deny_all(self, acl, target):
        acl.reset_and_set_acl({"deny": "all"})
        assert not target.is_reachable("/deny-all")

    def test_ip_asn(self, acl, target):
        acl.reset_and_set_acl({"deny": "asn:1239"})
        assert not target.is_reachable("/acl-asn", srcip="199.0.0.1")
        assert target.is_reachable("/")

    def test_ipv4(self, acl, target):
        acl.reset_and_set_acl({"deny": "ip:199-0-0-1"})
        assert not target.is_reachable("/acl-ipv4", srcip="199.0.0.1")
        assert target.is_reachable("/")

    def test_geo(self, acl, target):
        acl.reset_and_set_acl({"deny": "geo:us"})
        assert not target.is_reachable("/acl-geo", srcip="199.0.0.1")
        assert target.is_reachable("/")

    def test_ipv6(self, acl, target):
        acl.reset_and_set_acl({"deny": "ip:0000:0000:0000:0000:0000:0000:0000:0001"})
        assert not target.is_reachable("/acl-ipv6", srcip="0000:0000:0000:0000:0000:0000:0000:0001")
        assert target.is_reachable("/")


# --- Rate limit tests ---

# XXX test RateLimit conditions with attributes
# XXX test RateLimit Event with attributes
# XXX test RateLimit Actions
# XXX test RateLimit Limit by attributes (other than path & uri)

RL_RULES = []
MAP_PATH = {
}


def add_rl_rule(path, **kwargs):
    rule_id = f"e2e1{len(RL_RULES):0>9}"
    MAP_PATH[path] = rule_id
    RL_RULES.append({
        "id": rule_id,
        "name": "Rate Limit Rule 5/10 " + path,
        "description": "5 requests per 10 seconds",
        "ttl": "10",
        "limit": "5",
        "action": {
            "type": "default",
            "params": {"action": {"type": "default", "params": {}}},
        },
        "include": {
            "cookies": kwargs.get("incl_cookies", {}),
            "headers": kwargs.get("incl_headers", {}),
            "args": kwargs.get("incl_args", {}),
            "attrs": kwargs.get("incl_attrs", {}),
        },
        "exclude": {
            "cookies": kwargs.get("excl_cookies", {}),
            "headers": kwargs.get("excl_headers", {}),
            "args": kwargs.get("excl_args", {}),
            "attrs": kwargs.get("excl_attrs", {}),
        },
        "key": kwargs.get("key", {"attrs": "ip"}),
        "pairwith": kwargs.get("pairwith", {"self": "self"}),
    })


# RL scope
add_rl_rule("scope-cookies", incl_cookies={"include": "true"}, excl_cookies={"exclude": "true"})
add_rl_rule("scope-headers", incl_headers={"include": "true"}, excl_headers={"exclude": "true"})
add_rl_rule("scope-params", incl_args={"include": "true"}, excl_args={"exclude": "true"})
add_rl_rule("scope-path", incl_attrs={"path": "/scope-path/include/"}, excl_attrs={"path": "/scope-path/include/exclude/"})
add_rl_rule("scope-uri", incl_attrs={"uri": "/scope-uri/include/"}, excl_attrs={"uri": "/scope-uri/include/exclude/"})
# RL count by 1 value
add_rl_rule("countby-cookies", key=[{"cookies": "countby"}])
add_rl_rule("countby-headers", key=[{"headers": "countby"}])
add_rl_rule("countby-params", key=[{"args": "countby"}])
# RL count by 2 value (same type)
add_rl_rule("countby2-cookies", key=[{"cookies": "countby1"}, {"cookies": "countby2"}])
add_rl_rule("countby2-headers", key=[{"headers": "countby1"}, {"headers": "countby2"}])
add_rl_rule("countby2-params", key=[{"args": "countby1"}, {"args": "countby2"}])
# RL count by 2 value (different type)
add_rl_rule("countby-cookies-headers", key=[{"cookies": "countby"}, {"headers": "countby"}])
add_rl_rule("countby-headers-params", key=[{"headers": "countby"}, {"args": "countby"}])
add_rl_rule("countby-params-cookies", key=[{"args": "countby"}, {"cookies": "countby"}])
# RL Event condition
add_rl_rule("event-cookies", pairwith={"cookies": "event"})
add_rl_rule("event-headers", pairwith={"headers": "event"})
add_rl_rule("event-params", pairwith={"args": "event"})

RL_URLMAP = [
    {
        "id": "__default__",
        "name": "default entry",
        "match": "__default__",
        "map": [
            {
                "name": "default",
                "match": "/",
                "acl_profile": "__default__",
                "acl_active": True,
                "waf_profile": "__default__",
                "waf_active": True,
                "limit_ids": ["e2e100000000"],
            }
        ] + [
            {
                "name": k,
                "match": f"/{k}/",
                "acl_profile": "__default__",
                "acl_active": True,
                "waf_profile": "__default__",
                "waf_active": True,
                "limit_ids": [v],
            } for k, v in MAP_PATH.items()]
    }
]


@pytest.fixture(scope="class")
def ratelimit_config(cli):
    cli.revert_and_enable()
    # Add rule RL_RULES
    rl_rules = cli.call(f"doc get {TEST_CONFIG_NAME} ratelimits")
    rl_rules.extend(RL_RULES)
    cli.call(f"doc update {TEST_CONFIG_NAME} ratelimits /dev/stdin",
             inputjson=rl_rules)
    # Apply RL_URLMAP
    cli.call(f"doc update {TEST_CONFIG_NAME} urlmaps /dev/stdin",
             inputjson=RL_URLMAP)
    cli.publish_and_apply()


class TestRateLimit:
    def test_ratelimit_scope_include(self, target, ratelimit_config, section):
        # rate limit: max 5 requests within 10 seconds
        param = {section: {"include": "true"}}
        for i in range(1, 6):
            assert target.is_reachable(f"/scope-{section}/include/{i}", **param), \
                f"Request #{i} for {section} should be allowed"
        assert not target.is_reachable(f"/scope-{section}/include/6", **param), \
            f"Request #6 for {section} should be blocked by the rate limit"
        time.sleep(10)
        assert target.is_reachable(f"/scope-{section}/include/7", **param), \
            f"Request #7 for {section} should be allowed"

    def test_ratelimit_scope_include_exclude(self, target, ratelimit_config, section):
        # rate limit: max 5 requests within 10 seconds
        param = {section: {"include": "true", "exclude": "true"}}
        for i in range(1, 7):
            assert target.is_reachable(f"/scope-{section}/include-exclude/{i}", **param), \
                f"Request #{i} for {section} should be allowed"

    def test_ratelimit_scope_exclude(self, target, ratelimit_config, section):
        # rate limit: max 5 requests within 10 seconds
        param = {section: {"exclude": "true"}}
        for i in range(1, 7):
            assert target.is_reachable(f"/scope-{section}/exclude/{i}", **param), \
                f"Request #{i} for {section} should be allowed"

    def test_ratelimit_scope_path_include(self, target, ratelimit_config):
        # rate limit: max 5 requests within 10 seconds
        for i in range(1, 6):
            assert target.is_reachable(f"/scope-path/include/{i}"), \
                f"Request #{i} for path should be allowed"
        assert not target.is_reachable("/scope-path/include/6"), \
            "Request #6 for path should be blocked by the rate limit"
        time.sleep(10)
        assert target.is_reachable("/scope-path/include/7"), \
            "Request #7 for path should be allowed"

    def test_ratelimit_scope_path_include_exclude(self, target, ratelimit_config):
        # rate limit: max 5 requests within 10 seconds
        for i in range(1, 7):
            assert target.is_reachable(f"/scope-path/include/exclude/{i}"), \
                f"Request #{i} for path should be allowed"

    def test_ratelimit_scope_uri_include(self, target, ratelimit_config):
        # rate limit: max 5 requests within 10 seconds
        for i in range(1, 6):
            assert target.is_reachable(f"/scope-uri/include/{i}"), \
                f"Request #{i} for uri should be allowed"
        assert not target.is_reachable("/scope-uri/include/6"), \
            "Request #6 for uri should be blocked by the rate limit"
        time.sleep(10)
        assert target.is_reachable("/scope-uri/include/7"), \
            "Request #7 for uri should be allowed"

    def test_ratelimit_scope_uri_include_exclude(self, target, ratelimit_config):
        # rate limit: max 5 requests within 10 seconds
        for i in range(1, 7):
            assert target.is_reachable(f"/scope-uri/include/exclude/{i}"), \
                f"Request #{i} for uri should be allowed"

    def test_ratelimit_countby_section(self, target, ratelimit_config, section):
        param1 = {section: {"countby": "1"}}
        param2 = {section: {"countby": "2"}}
        for i in range(1, 6):
            assert target.is_reachable(f"/countby-{section}/1/{i}", **param1), \
                f"Request #{i} with {section} countby 1 should be allowed"
            assert target.is_reachable(f"/countby-{section}/2/{i}", **param2), \
                f"Request #{i} with {section} countby 2 should be allowed"
            # empty {section} -> not counted
            # assert target.is_reachable(f"/countby-{section}/3/{i}"), \
            #     f"Request #{i} with no {section} should be allowed"
        assert not target.is_reachable(f"/countby-{section}/2/6", **param1), \
            f"Request #6 with {section} countby 1 should be blocked"
        assert not target.is_reachable(f"/countby-{section}/2/6", **param2), \
            f"Request #6 with {section} countby 2 should be blocked"
        # assert not target.is_reachable(f"/countby-{section}/3/6"), \
        #     f"Request #{i} with no {section} should not be allowed"
        time.sleep(10)
        assert target.is_reachable(f"/countby-{section}/2/7", **param1), \
            f"Request #7 with {section} countby 1 should be allowed"
        assert target.is_reachable(f"/countby-{section}/2/7", **param2), \
            f"Request #7 with {section} countby 2 should be allowed"
        # assert target.is_reachable(f"/countby-{section}/3/7"), \
        #     f"Request #{i} with no {section} should not be allowed"

    def test_ratelimit_countby2_section(self, target, ratelimit_config, section):
        param1 = {section: {"countby1": "1"}}
        param2 = {section: {"countby2": "1"}}
        param12 = {section: {"countby1": "1", "countby2": "1"}}
        for i in range(1, 6):
            assert target.is_reachable(f"/countby2-{section}/1/{i}", **param1), \
                f"Request #{i} with {section} countby 1 should be allowed"
            assert target.is_reachable(f"/countby2-{section}/2/{i}", **param2), \
                f"Request #{i} with {section} countby 2 should be allowed"
            assert target.is_reachable(f"/countby2-{section}/2/{i}", **param12), \
                f"Request #{i} with {section} countby 1&2 should be allowed"
        assert target.is_reachable(f"/countby2-{section}/2/6", **param1), \
            f"Request #6 with {section} countby 1 should not be blocked"
        assert target.is_reachable(f"/countby2-{section}/2/6", **param2), \
            f"Request #6 with {section} countby 2 should not be blocked"
        assert not target.is_reachable(f"/countby2-{section}/2/6", **param12), \
            f"Request #6 with {section} countby 1&2 should be blocked"
        time.sleep(10)
        assert target.is_reachable(f"/countby2-{section}/2/7", **param1), \
            f"Request #7 with {section} countby 1 should be allowed"
        assert target.is_reachable(f"/countby2-{section}/2/7", **param2), \
            f"Request #7 with {section} countby 2 should be allowed"
        assert target.is_reachable(f"/countby2-{section}/2/7", **param12), \
            f"Request #7 with {section} countby 1&2 should be allowed"

    def test_ratelimit_countby_2sections(self, target, ratelimit_config, section):
        # condition: have countby set for 2 sections
        othersection = {"headers": "params", "cookies": "headers", "params": "cookies"}[section]
        param1 = {section: {"countby": "1"}}
        param2 = {othersection: {"countby": "1"}}
        param12 = {section: {"countby": "1"}, othersection: {"countby": "1"}}
        for i in range(1, 6):
            assert target.is_reachable(f"/countby-{section}-{othersection}/1/{i}", **param1), \
                f"Request #{i} with {section} countby 1 should be allowed"
            assert target.is_reachable(f"/countby-{section}-{othersection}/2/{i}", **param2), \
                f"Request #{i} with {section} countby 2 should be allowed"
            assert target.is_reachable(f"/countby-{section}-{othersection}/2/{i}", **param12), \
                f"Request #{i} with {section} countby 1&2 should be allowed"
        assert target.is_reachable(f"/countby-{section}-{othersection}/2/6", **param1), \
            f"Request #6 with {section} countby 1 should not be blocked"
        assert target.is_reachable(f"/countby-{section}-{othersection}/2/6", **param2), \
            f"Request #6 with {section} countby 2 should not be blocked"
        assert not target.is_reachable(f"/countby-{section}-{othersection}/2/6", **param12), \
            f"Request #6 with {section} countby 1&2 should be blocked"
        time.sleep(10)
        assert target.is_reachable(f"/countby-{section}-{othersection}/2/7", **param1), \
            f"Request #7 with {section} countby 1 should be allowed"
        assert target.is_reachable(f"/countby-{section}-{othersection}/2/7", **param2), \
            f"Request #7 with {section} countby 2 should be allowed"
        assert target.is_reachable(f"/countby-{section}-{othersection}/2/7", **param12), \
            f"Request #7 with {section} countby 1&2 should be allowed"

    def test_ratelimit_event_section(self, target, ratelimit_config, section):
        params = [{section: {"event": f"{i}"}} for i in range(1, 7)]
        for i in range(5):
            assert target.is_reachable(f"/event-{section}/1/{i}", **params[i]), \
                f"Request for value #{i+1} with {section} event should be allowed"
        assert not target.is_reachable(f"/event-{section}/1/{i}", **params[5]), \
            f"Request for value #{i+1} with {section} event should not be allowed"
        for i in range(5):
            assert not target.is_reachable(f"/event-{section}/1/{i}", **params[i]), \
                f"Request for value #{i+1} with {section} event should not be allowed"
        time.sleep(10)
        for i in range(5):
            assert target.is_reachable(f"/event-{section}/1/{i}", **params[i]), \
                f"Request for value #{i+1} with {section} event should be allowed"


# --- Tag rules tests (formerly profiling lists) ---

TEST_TAGRULES = {
    "id": "e2e000000000",
    "name": "e2e test tag rules",
    "source": "self-managed",
    "mdate": "2020-11-22T00:00:00.000Z",
    "notes": "E2E test tag rules",
    "entries_relation": "OR",
    "active": True,
    "tags": ["e2e-test"],
    "rule": {
        "relation": "OR",
        "sections": [
            {
                "relation": "OR",
                "entries": [
                    ["cookies", ["e2e", "value"], "annotation"],
                    ["headers", ["e2e", "value"], "annotation"],
                    ["method", "(POST|PUT)", "annotation"],
                    ["path", "/e2e-tagrules-path/", "annotation"],
                    ["query", "e2e=value", "annotation"],
                    ["uri", "/e2e-tagrules-uri", "annotation"],
                    ["ip", "0000:0000:0000:0000:0000:0000:0000:0001", "annotation"],
                    ["ip", "199.0.0.1", "annotation"],
                    ["country", "jp", "annotation"],
                    ["asn", "13335", "annotation"],
                ],
            },
            {
                "relation": "AND",
                "entries": [
                    ["path", "/e2e-and/", "annotation"],
                    ["cookies", ["e2e-and", "value"], "annotation"],
                ],
            },
        ],
    },
}


@pytest.fixture(scope="session", params=[True, False], ids=["active", "inactive"])
def active(request):
    return request.param


@pytest.fixture(scope="class")
def tagrules_config(cli, acl, active):
    cli.revert_and_enable()
    acl.set_acl({"force_deny": "e2e-test", "bypass": "all"})
    # Apply TEST_TAGRULES
    TEST_TAGRULES["active"] = active
    # 'updating' wafpolicies with a list containing a single entry adds this
    # entry, without removing pre-existing ones.
    cli.call(f"doc update {TEST_CONFIG_NAME} tagrules /dev/stdin",
             inputjson=[TEST_TAGRULES])
    cli.publish_and_apply()


class TestTagRules:
    def test_cookies(self, target, tagrules_config, active):
        assert target.is_reachable(
            "/e2e-tagrules-cookies", cookies={"e2e": "value"}) is not active
        assert target.is_reachable(
            "/e2e-tagrules-cookies", cookies={"e2e": "allowed"}) is True

    def test_headers(self, target, tagrules_config, active):
        assert target.is_reachable(
            "/e2e-tagrules-headers", headers={"e2e": "value"}) is not active
        assert target.is_reachable(
            "/e2e-tagrules-headers", headers={"e2e": "allowed"}) is True

    def test_method(self, target, tagrules_config, active):
        assert target.is_reachable(
            "/e2e-tagrules-method-GET", method="GET") is True
        assert target.is_reachable(
            "/e2e-tagrules-method-POST", method="POST") is not active
        assert target.is_reachable(
            "/e2e-tagrules-method-PUT", method="PUT") is not active

    def test_path(self, target, tagrules_config, active):
        assert target.is_reachable(
            "/e2e-tagrules-path/") is not active
        assert target.is_reachable(
            "/e2e-tagrules-valid-path/") is True

    def test_query(self, target, tagrules_config, active):
        assert target.is_reachable(
            "/e2e-tagrules-query", params={"e2e": "value"}) is not active
        assert target.is_reachable(
            "/e2e-tagrules-query", params={"e2e": "allowed"}) is True

    def test_uri(self, target, tagrules_config, active):
        assert target.is_reachable(
            "/e2e-tagrules-uri") is not active
        assert target.is_reachable(
            "/e2e-tagrules-allowed-uri") is True

    def test_ipv4(self, target, tagrules_config, active):
        assert target.is_reachable("/tag-ipv4-1", srcip="199.0.0.1") is not active
        assert target.is_reachable("/tag-ipv4-2", srcip="199.0.0.2") is True

    def test_ipv6(self, target, tagrules_config, active):
        assert target.is_reachable(
            "/tag-ipv6-1", srcip="0000:0000:0000:0000:0000:0000:0000:0001") is not active
        assert target.is_reachable(
            "/tag-ipv6-2", srcip="0000:0000:0000:0000:0000:0000:0000:0002") is True

    def test_country(self, target, tagrules_config, active):
        # JP address (Softbank)
        assert target.is_reachable("/tag-country", srcip="126.0.0.0") is not active

    def test_asn(self, target, tagrules_config, active):
        # ASN 13335
        assert target.is_reachable("/tag-asn", srcip="1.1.1.1") is not active

    def test_and(self, target, tagrules_config, active):
        assert target.is_reachable(
            "/e2e-and/", cookies={"e2e-and": "value"}) is not active
        assert target.is_reachable(
            "/not-e2e-and/", cookies={"e2e-and": "value"}) is True
        assert target.is_reachable(
            "/e2e-and/", cookies={"not-e2e-and": "value"}) is True

# --- URL Maps tests ---


ACL_BYPASSALL = {
    "id": "e2e00ac10000",
    "name": "e2e-denyall-acl",
    "allow": [],
    "allow_bot": [],
    "deny_bot": [],
    "bypass": ["all"],
    "force_deny": [],
    "deny": [],
}

WAF_SHORT_HEADERS = {
    "id": "e2e000000002",
    "name": "e2e waf short headers",
    "ignore_alphanum": True,
    "max_header_length": 50,
    "max_cookie_length": 1024,
    "max_arg_length": 1024,
    "max_headers_count": 42,
    "max_cookies_count": 42,
    "max_args_count": 512,
    "args": {"names": [], "regex": []},
    "headers": {"names": [], "regex": []},
    "cookies": {"names": [], "regex": []},
}

URLMAP = [
    {
        "id": "e2e000000001",
        "name": "e2e URL map",
        "match": ".*",
        "map": [
            {
                "name": "acl",
                "match": "/acl/",
                "acl_profile": "__default__",
                "acl_active": True,
                "waf_profile": "__default__",
                "waf_active": False,
                "limit_ids": [],
                "isnew": True,
            },
            {
                "name": "acl-bypassall",
                "match": "/acl-bypassall/",
                "acl_profile": "e2e00ac10000",
                "acl_active": True,
                "waf_profile": "__default__",
                "waf_active": True,
                "limit_ids": [],
                "isnew": True,
            },
            {
                "name": "acl-waf",
                "match": "/acl-waf/",
                "acl_profile": "__default__",
                "acl_active": True,
                "waf_profile": "__default__",
                "waf_active": True,
                "limit_ids": [],
                "isnew": True,
            },
            {
                "name": "waf",
                "match": "/waf/",
                "acl_profile": "__default__",
                "acl_active": False,
                "waf_profile": "__default__",
                "waf_active": True,
                "limit_ids": [],
                "isnew": True,
            },
            {
                "name": "waf-short-headers",
                "match": "/waf-short-headers/",
                "acl_profile": "__default__",
                "acl_active": False,
                "waf_profile": "e2e000000002",
                "waf_active": True,
                "limit_ids": [],
                "isnew": True,
            },
            {
                "name": "nofilter",
                "match": "/nofilter/",
                "acl_profile": "__default__",
                "acl_active": False,
                "waf_profile": "__default__",
                "waf_active": False,
                "limit_ids": [],
            },
        ],
    }
]


@pytest.fixture(scope="class")
def urlmap_config(cli, acl):
    cli.revert_and_enable()
    # Add ACL entry
    default_acl = cli.empty_acl()
    default_acl[0]["force_deny"].append("all")
    default_acl.append(ACL_BYPASSALL)
    cli.call(f"doc update {TEST_CONFIG_NAME} aclpolicies /dev/stdin",
             inputjson=default_acl)
    # Add waf profile entry
    wafpolicy = cli.call(f"doc get {TEST_CONFIG_NAME} wafpolicies")
    wafpolicy.append(WAF_SHORT_HEADERS)
    cli.call(f"doc update {TEST_CONFIG_NAME} wafpolicies /dev/stdin",
             inputjson=wafpolicy)
    # Add urlmap entry URLMAP
    cli.call(f"doc update {TEST_CONFIG_NAME} urlmaps /dev/stdin",
             inputjson=URLMAP)
    cli.publish_and_apply()


class TestURLMap:
    def test_nofilter(self, target, urlmap_config):
        assert target.is_reachable("/nofilter/")
        assert target.is_reachable(
            "/nofilter/", headers={"Long-header": "Overlong_header"*100})

    def test_waffilter(self, target, urlmap_config):
        assert target.is_reachable("/waf/")
        assert not target.is_reachable(
            "/waf/", headers={"Long-header": "Overlong_header"*100})

    def test_aclfilter(self, target, urlmap_config):
        assert not target.is_reachable("/acl/")
        assert not target.is_reachable(
            "/acl/", headers={"Long-header": "Overlong_header"*100})

    def test_nondefault_aclfilter_bypassall(self, target, urlmap_config):
        assert target.is_reachable("/acl-bypassall/")
        assert target.is_reachable(
            "/acl-bypassall/", headers={"Long-header": "Overlong_header"*100})

    def test_aclwaffilter(self, target, urlmap_config):
        assert not target.is_reachable("/acl-waf/")
        assert not target.is_reachable(
            "/acl/", headers={"Long-header": "Overlong_header"*100})

    def test_nondefault_wafpolicy_short_headers(self, target, urlmap_config):
        assert target.is_reachable(
            "/waf-short-headers/", headers={"Short-header": "0123456789"*5})
        assert not target.is_reachable(
            "/waf-short-headers/", headers={"Long-header": "0123456789"*5+"A"})


# --- WAF Policies tests (formerly WAF profiles) ---

class TestWAFLengthCount:
    def test_length_overlong(self, default_config, target, section):
        # default limit: len 1024
        assert not target.is_reachable(
            f"/overlong-{section}",
            **{section: {f"Long-{section}": f"Overlong_{section}"*100}}), \
            f"Reachable despite overlong {section}"

    def test_length_short(self, default_config, target, section):
        assert target.is_reachable(
            f"/short-{section}",
            headers={f"Short-{section}": f"Short_{section}"}), \
            f"Not reachable despite short {section}"

    def test_count_few(self, default_config, target, section):
        # default limit: 512 for args, 42 for other sections
        values = {}
        for i in range(10):
            values[f"{section}-{i}"] = "not_alphanum"
        assert target.is_reachable(
            f"/few-{section}",
            **{section: values}), \
            f"Not reachable despite few {section}"

    def test_count_toomany(self, default_config, target, section):
        values = {}
        for i in range(513):
            values[f"{section}-{i}"] = "not_alphanum"
        assert not target.is_reachable(
            f"/too-many-{section}",
            **{section: values}), \
            f"Reachable despite too many {section}"


WAF_PARAM_CONSTRAINTS = {
    "names": [
        {
            "key": "name-norestrict",
            "reg": "value",
            "restrict": False,
            "exclusions": {"100140": 1}
        },
        {
            "key": "name-restrict",
            "reg": "value",
            "restrict": True,
            "exclusions": {}
        }
    ],
    "regex": [
        {
            "key": "regex-norestrict",
            "reg": "[v]+[a]{1}l?u*e",
            "restrict": False,
            "exclusions": {"100140": 1}
        },
        {
            "key": "regex-restrict",
            "reg": "[v]+[a]{1}l?u*e",
            "restrict": True,
            "exclusions": {}
        }
    ]
}


@pytest.fixture(scope="session", params=[True, False],
                ids=["ignore_alphanum", "no_ignore_alphanum"])
def ignore_alphanum(request):
    return request.param


@pytest.fixture(scope="class")
def wafparam_config(cli, request, ignore_alphanum):
    cli.revert_and_enable()
    # Apply WAF_PARAM_CONSTRAINTS
    wafpolicy = cli.call(f"doc get {TEST_CONFIG_NAME} wafpolicies")
    for k in ("args", "headers", "cookies"):
        wafpolicy[0][k] = WAF_PARAM_CONSTRAINTS
    wafpolicy[0]["ignore_alphanum"] = ignore_alphanum
    cli.call(f"doc update {TEST_CONFIG_NAME} wafpolicies /dev/stdin",
             inputjson=wafpolicy)

    cli.publish_and_apply()


@pytest.fixture(scope="session", params=["name", "regex"])
def name_regex(request):
    return request.param


@pytest.fixture(scope="session", params=["restrict", "norestrict"])
def restrict(request):
    return request.param


class TestWAFParamsConstraints:
    def test_allowlisted_value(self, wafparam_config, section, name_regex, restrict, target):
        paramname = name_regex + "-" + restrict
        assert target.is_reachable(
            f"/allowlisted-value-{paramname}",
            **{section: {paramname: "value"}}), \
            f"Not reachable despite allowlisted {section} value"

    def test_non_allowlisted_value_restrict(self, wafparam_config, section, name_regex, target, ignore_alphanum):
        paramname = name_regex + "-restrict"
        if ignore_alphanum:
            assert target.is_reachable(
                f"/blocklisted-value-{paramname}-restrict-ignore_alphanum",
                **{section: {paramname: "invalid"}}), \
                f"Not reachable despite alphanum blocklisted {section} value (restrict is enabled)"
        else:
            assert not target.is_reachable(
                f"/blocklisted-value-{paramname}-restrict",
                **{section: {paramname: "invalid"}}), \
                f"Reachable despite blocklisted {section} value (restrict is enabled)"

    def test_non_allowlisted_value_norestrict_nowafmatch(self, wafparam_config, section, name_regex, target):
        paramname = name_regex + "-norestrict"
        assert target.is_reachable(
            f"/blocklisted-value-{paramname}",
            **{section: {paramname: "invalid"}}), \
            f"Not reachable despite 'restricted' not checked (non-matching {section} value)"

    def test_non_allowlisted_value_norestrict_wafmatch(self, wafparam_config, section, name_regex, target):
        paramname = name_regex + "-norestrict"
        assert not target.is_reachable(
            f"/blocklisted-value-{paramname}-wafmatch",
            **{section: {paramname: "../../../../../"}}), \
            f"Reachable despite matching wafsig 100116 (non-matching {section} value)"

    def test_non_allowlisted_value_norestrict_wafmatch_excludesig(self, wafparam_config, section, name_regex, target):
        paramname = name_regex + "-norestrict"
        assert target.is_reachable(
            f"/blocklisted-value-{paramname}-wafmatch-excludedsig",
            **{section: {paramname: "htaccess"}}), \
            f"Not reachable despite excludesig for rule 100140 ({section} value)"

# --- WAF Rules tests (formerly WAF Signatures) ---


@pytest.fixture(scope="session", params=[
    (100140, "htaccess"),
    (100116, "../../../../../")])
def wafrules(request):
    return request.param


class TestWAFRules:
    def test_wafsig(self, default_config, target, section, wafrules):
        ruleid, rulestr = wafrules
        assert not target.is_reachable(
            f"/wafsig-{section}",
            **{section: {"key": rulestr}}), \
            f"Reachable despite matching rule {ruleid}"
