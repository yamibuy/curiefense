mod iptools;
mod lua;

use crate::lua::Luagrasshopper;

use anyhow::anyhow;
use curiefense::interface::Tags;
use curiefense::utils::RequestMeta;
use mlua::prelude::*;
use std::collections::HashMap;

use curiefense::config::waf::Transformation;
use curiefense::inspect_generic_request_map;
use curiefense::interface::{Decision, Grasshopper};
use curiefense::logs::Logs;
use curiefense::utils::{map_request, InspectionResult};
use curiefense::waf_check_generic_request_map;

// ******************************************
// WAF ONLY CHECKS
// ******************************************

/// Lua interface to the inspection function
///
/// args are
/// * meta (contains keys "method", "path", and optionally "authority")
/// * headers
/// * (opt) body
/// * ip addr
/// * (opt) grasshopper
#[allow(clippy::type_complexity)]
#[allow(clippy::unnecessary_wraps)]
fn lua_inspect_waf(
    _lua: &Lua,
    args: (
        HashMap<String, String>, // meta
        HashMap<String, String>, // headers
        Option<LuaString>,       // maybe body
        String,                  // ip
        String,                  // waf_id
    ),
) -> LuaResult<(String, Option<String>)> {
    let (meta, headers, lua_body, str_ip, waf_id) = args;

    let res = match lua_body {
        None => inspect_waf("/cf-config/current/config", meta, headers, None, str_ip, waf_id),
        Some(body) => inspect_waf(
            "/cf-config/current/config",
            meta,
            headers,
            Some(body.as_bytes()),
            str_ip,
            waf_id,
        ),
    };

    Ok(match res {
        Err(rr) => (
            Decision::Pass.to_json_raw(serde_json::Value::Null, Logs::default()),
            Some(rr),
        ),
        Ok(ir) => ir.into_json(),
    })
}

/// Rust-native inspection top level function
fn inspect_waf(
    configpath: &str,
    meta: HashMap<String, String>,
    headers: HashMap<String, String>,
    mbody: Option<&[u8]>,
    ip: String,
    waf_id: String,
) -> Result<InspectionResult, String> {
    let mut logs = Logs::default();
    logs.debug("Inspection init");
    let rmeta: RequestMeta = RequestMeta::from_map(meta)?;

    let reqinfo = map_request(&mut logs, &Transformation::DEFAULTPOLICY, ip, headers, rmeta, mbody)?;

    let dec = waf_check_generic_request_map(configpath, &reqinfo, &waf_id, &mut logs);
    Ok(InspectionResult {
        decision: dec,
        tags: None,
        logs,
        err: None,
        rinfo: Some(reqinfo),
    })
}

// ******************************************
// FULL CHECKS
// ******************************************

/// Lua interface to the inspection function
///
/// args are
/// * meta (contains keys "method", "path", and optionally "authority")
/// * headers
/// * (opt) body
/// * ip addr
/// * (opt) grasshopper
#[allow(clippy::type_complexity)]
#[allow(clippy::unnecessary_wraps)]
fn lua_inspect_request(
    _lua: &Lua,
    args: (
        HashMap<String, String>, // meta
        HashMap<String, String>, // headers
        Option<LuaString>,       // maybe body
        String,                  // ip
        Option<LuaTable>,        // grasshopper
    ),
) -> LuaResult<(String, Option<String>)> {
    let (meta, headers, lua_body, str_ip, lua_grasshopper) = args;
    let grasshopper = lua_grasshopper.map(Luagrasshopper);

    // TODO: solve the lifetime issue for the &[u8] to reduce duplication
    let res = match lua_body {
        None => inspect_request("/cf-config/current/config", meta, headers, None, str_ip, grasshopper),
        Some(body) => inspect_request(
            "/cf-config/current/config",
            meta,
            headers,
            Some(body.as_bytes()),
            str_ip,
            grasshopper,
        ),
    };

    Ok(match res {
        Err(rr) => (
            Decision::Pass.to_json_raw(serde_json::Value::Null, Logs::default()),
            Some(rr),
        ),
        Ok(ir) => ir.into_json(),
    })
}

/// Rust-native inspection top level function
fn inspect_request<GH: Grasshopper>(
    configpath: &str,
    meta: HashMap<String, String>,
    headers: HashMap<String, String>,
    mbody: Option<&[u8]>,
    ip: String,
    grasshopper: Option<GH>,
) -> Result<InspectionResult, String> {
    let mut logs = Logs::default();
    logs.debug("Inspection init");
    let rmeta: RequestMeta = RequestMeta::from_map(meta)?;

    let reqinfo = map_request(&mut logs, &Transformation::DEFAULTPOLICY, ip, headers, rmeta, mbody)?;

    let (dec, tags, masked_rinfo) =
        inspect_generic_request_map(configpath, grasshopper, reqinfo, Tags::default(), &mut logs);

    Ok(InspectionResult {
        decision: dec,
        tags: Some(tags),
        logs,
        err: None,
        rinfo: Some(masked_rinfo),
    })
}

/// wraps a result into a go-like pair
#[allow(clippy::unnecessary_wraps)]
fn lua_result<R>(v: anyhow::Result<R>) -> LuaResult<(Option<R>, Option<String>)> {
    Ok(match v {
        Ok(x) => (Some(x), None),
        Err(rr) => (None, Some(format!("{}", rr))),
    })
}

/// wraps a result into a go-like pair, PRINTING LOGS
#[allow(clippy::unnecessary_wraps)]
fn lua_log_result<F, R>(f: F) -> LuaResult<(Option<R>, Option<String>)>
where
    F: FnOnce(&mut Logs) -> anyhow::Result<R>,
{
    let mut logs = Logs::default();
    let v = f(&mut logs);
    for log in logs.logs {
        println!("{}", log.to_string());
    }
    Ok(match v {
        Ok(x) => (Some(x), None),
        Err(rr) => (None, Some(format!("{}", rr))),
    })
}

/// runs the passed function, assuming the argument is a string
fn with_str<F, R>(lua: &Lua, session_id: LuaValue, f: F) -> anyhow::Result<R>
where
    F: FnOnce(&str) -> anyhow::Result<R>,
{
    let decoded: String = FromLua::from_lua(session_id, lua).map_err(|rr| anyhow!("{}", rr))?;
    f(&decoded)
}

/// runs the underlying string using function, catching mlua errors
fn wrap_session<F, R>(lua: &Lua, session_id: LuaValue, f: F) -> LuaResult<(Option<R>, Option<String>)>
where
    F: FnOnce(&str) -> anyhow::Result<R>,
{
    lua_result(with_str(lua, session_id, f))
}

/// runs the underlying string using, json returning, function, catching mlua errors
fn wrap_session_json<F, R: serde::Serialize>(
    lua: &Lua,
    session_id: LuaValue,
    f: F,
) -> LuaResult<(Option<String>, Option<String>)>
where
    F: FnOnce(&mut Logs, &str) -> anyhow::Result<R>,
{
    lua_log_result(|logs| {
        with_str(lua, session_id, |s| {
            f(logs, s).and_then(|r| serde_json::to_string(&r).map_err(|rr| anyhow!("{}", rr)))
        })
    })
}

#[mlua::lua_module]
fn curiefense(lua: &Lua) -> LuaResult<LuaTable> {
    let exports = lua.create_table()?;

    // end-to-end inspection
    exports.set("inspect_request", lua.create_function(lua_inspect_request)?)?;
    // waf inspection
    exports.set("inspect_waf", lua.create_function(lua_inspect_waf)?)?;

    // iptools exports
    exports.set("new_ip_set", lua.create_function(iptools::new_ip_set)?)?;
    exports.set("new_sig_set", lua.create_function(iptools::new_sig_set)?)?;
    exports.set("new_geoipdb", lua.create_function(iptools::new_geoipdb)?)?;
    exports.set("modhash", lua.create_function(iptools::modhash)?)?;
    exports.set("iptonum", lua.create_function(iptools::iptonum)?)?;
    exports.set("encodeurl", lua.create_function(iptools::encodeurl)?)?;
    exports.set("test_regex", lua.create_function(iptools::test_regex)?)?;

    Ok(exports)
}

#[cfg(test)]
mod tests {
    use super::*;
    use curiefense::config::with_config;

    #[test]
    fn config_load() {
        let mut logs = Logs::default();
        let cfg = with_config("../../cf-config", &mut logs, |_, c| c.clone());
        if cfg.is_some() {
            match logs.logs.len() {
                2 => {
                    assert!(logs.logs[0].message.to_string().contains("CFGLOAD"));
                    assert!(logs.logs[1].message.to_string().contains("globalfilter-lists.json"));
                }
                10 => {
                    assert!(logs.logs[0]
                        .message
                        .to_string()
                        .contains("../../cf-config: No such file or directory"))
                }
                n => {
                    for r in logs.logs.iter() {
                        println!("{}", r.to_string());
                    }
                    panic!("Invalid amount of logs: {}", n);
                }
            }
        }
    }
}
