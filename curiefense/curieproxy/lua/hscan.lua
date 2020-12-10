module(..., package.seeall)

luahs = require "luahs"

hscandb = luahs.compile {
    expressions = {
        {
            expression = [==[\s(and|or)\s+\d+\s+.*between\s.*\d+\s+and\s+\d+.*]==],
            id = 100000,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[\s(and|or)\s+["']\w+["']\s+.*between\s.*["']\w+["']\s+and\s+["']\w+.*]==],
            id = 100001,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[\W(\s*)?(and|or)\s.*('|").+('|")(\s+)?(=|>|<|>=|<=).*('|").+]==],
            id = 100002,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[\W(\s*)?(and|or)\s.*\w.*(=|>|<|>=|<=).*\w]==],
            id = 100003,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[.*\W(\s*)?(and|or)\s.+(r?like)\s.*['"]((%\w|\w%)|.+).*]==],
            id = 100004,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[\W(\s*)?(and|or)\s.*\d+.*(=|>|<|>=|<=).*\d+]==],
            id = 100005,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[(("|')\s|;).*(drop|create)\s+(table|function)\s+.+]==],
            id = 100006,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[("|'|\s|;)delete\s+from\s+.+(--|'|"|;)]==],
            id = 100007,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[('|"|;)(\s+)?select\s+(\*|((`|")?\w+(`|")?,\s){1,}).+\s+from\s+]==],
            id = 100008,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[('|"|;)(\s+)?select\s+.+\s+from]==],
            id = 100009,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[(("|')\s|;).*(insert|replace).*\s.*into.*\s]==],
            id = 100010,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[(("|')\s|;).*(update)(\s|\+).*set\s.*\w.*=.+]==],
            id = 100011,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[(("|')\s|;).*(select)(\s|\+|;|')(pg_sleep|sleep).*\(.+]==],
            id = 100012,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[\W(waitfor).*(\s).*(delay).*(\d+:)]==],
            id = 100013,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[("|').*exec\s]==],
            id = 100014,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[(\b|\s).*(union|intersect|except).*(\s+all)?.+select([^\w]|\s)]==],
            id = 100015,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[xp_(makecab|cmdshell|execresultset|regaddmultistring|regread|enumdsn|availablemedia|regdeletekey|loginconfig|regremovemultistring|regwrite|regdeletevalue|dirtree|regenumkeys|filelist|terminate|servicecontrol|ntsec_enumdomains|terminate_process|ntsec|regenumvalues|cmdshell)]==],
            id = 100016,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[(information_schema|connection_id|iif|benchmark|sha1|md5)(\s)?\(]==],
            id = 100017,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[sp_(execute|prepare|password|sqlexec|replwritetovarbin|help|addextendedproc|executesql|makewebtask|oacreate)]==],
            id = 100018,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[\W(and|or|;)\s*(abs|acos|adddate|addtime|aes_decrypt|aes_encrypt|and|atan2|atan|atan|avg|benchmark|bin|binary|bit_and|bit_count|bit_length|bit_or|bit_xor|cast|ceil|ceiling|char_length|char|character_length|charset|coalesce|coercibility|collation|compress|concat_ws|concat|connection_id|conv|convert_tz|convert|cos|cot|count(distinct)|count|crc32|curdate|current_date|current_date|current_time|current_time|current_timestamp|current_timestamp|current_user|current_user|curtime|database|date_add|date_format|date_sub|date|datediff|day|dayname|dayofmonth|dayofweek|dayofyear|decode|default|degrees|des_decrypt|des_encrypt|elt|encode|encrypt|exp|export_set|extract|extractvalue|field|find_in_set|floor|format|found_rows|from_days|from_unixtime|get_format|get_lock|greatest|group_concat|hex|hour|if|ifnull|in|inet_aton|inet_ntoa|insert|instr|interval|is_free_lock|is_used_lock|isnull|last_insert_id|lcase|least|left|length|ln|load_file|localtime|localtimestamp|locate|log10|log2|log|lower|lpad|ltrim|make_set|makedate|maketime|master_pos_wait|match|max|md5|microsecond|mid|min|minute|mod|month|monthname|name_const|now|nullif|oct|octet_length|old_password|ord|password|period_add|period_diff|pi|position|pow|power|procedure analyse|quarter|quote|radians|rand|regexp|release_lock|repeat|replace|reverse|right|rlike|round|row_count|rpad|rtrim|schema|sec_to_time|second|session_user|sha1|sha|sign|sin|sleep|soundex|sounds like|space|sqrt|std|stddev_pop|stddev_samp|stddev|str_to_date|strcmp|subdate|substr|substring_index|substring|subtime|sum|sysdate|system_user|tan|time_format|time_to_sec|time|timediff|timestamp|timestampadd|timestampdiff|to_days|trim|truncate|ucase|uncompress|uncompressed_length|unhex|unix_timestamp|updatexml|upper|user|utc_date|utc_time|utc_timestamp|uuid_short|uuid|values|var_pop|var_samp|variance|version|week|weekday|weekofyear|year|yearweek)(\s)?\(]==],
            id = 100019,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[\W(abs|acos|ascii|asin|atan|atn2|avg|cast|ceiling|char|charindex|coalesce|col_length|col_name|convert|cos|cot|count|count|count|count|current_timestamp|current_user|datalength|databasepropertyex|dateadd|datediff|datename|datepart|day|db_id|db_name|degrees|difference|exp|floor|file_id|file_name|filegroup_id|filegroup_name|filegroupproperty|fileproperty|fulltextcatalogproperty|fulltextserviceproperty|formatmessage|freetexttable|getdate|getansinull|host_id|host_name|ident_incr|ident_seed|ident_current|identity|index_col|indexproperty|isdate|is_member|is_srvrolemember|isnull|isnumeric|left|len|log|log10|lower|ltrim|max|min|month|nchar|newid|nullif|object_id|object_name|objectproperty|open|opendatasource|openquery|openrowset|parsename|patindex|permissions|pi|power|radians|rand|replicate|replace|reverse|right|rtrim|round|rowcount_big|session_user|sign|sin|soundex|space|stats_date|stdev|stdevp|str|stuff|substring|sum|suser_id|suser_sid|suser_sname|system_user|tan|textptr|textvalid|typeproperty|unicode|user|user_id|user_name|upper|var|varp|year)(\s)?\(.+\)]==],
            id = 100020,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[(dbms_alert|dbms_application_info|v\$session|v\$session_longops|dbms_aq|dbms_aqadm|dbms_aqelm|dbms_backup_restore|dbms_ddl|dbms_debug|dbms_defer|dbms_defer_query|dmbs_defer_sys|dbms_describe|dbms_distributed_trust_admin|dbms_encode|dbms_fga|dmbs_flashback|dbms_hs_passthrough|dbms_iot|dbms_job|dbms_ldap|dbms_libcache|dbms_lob|dbms_lock|dbms_logmnr|dbms_logmnr_cdc_publish|dbms_logmnr_cdc_subscribe|dbms_logmnr_d|dbms_metadata|dbms_mview|dbms_obfuscation_toolkit|dbms_odci|dbms_offline_og|dbms_offline_snapshot|dbms_olap|dbms_oracle_trace_agent|dbms_oracle_trace_user|dbms_outln|dbms_outln_edit|dbms_output|dbms_pclxutil|dbms_pipe|dbms_profiler|dbms_random|dbms_rectifier_diff|dbms_redefinition|dbms_refresh|dbms_repair|dbms_repcat|dbms_repcat_admin|dbms_repcat_instatiate|dbms_repcat_rgt|dbms_reputil|dbms_resource_manager|dbms_resource_manager_privs|dbms_resumable|dbms_rls|dbms_rowid|dbms_session|dbms_shared_pool|dbms_snapshot|dbms_space|dbms_space_admin|dbms_sql|dbms_stats|dbms_trace|dbms_transaction|dbms_transform|dbms_tts|dbms_types|dbms_url|dbms_utility|dbms_wm|dbms_xmlgen|dmbs_xmlquery|dbms_xmlsave|debug_extproc|outln_pkg|sdo_cs|sdo_geom|sdo_lrs|sdo_migrate|sdo_tune|utl_coll|utl_encode|utl_file|utl_http|utl_inaddr|utl_pg|utl_raw|utl_ref|utl_smtp|utl_tcp|utl_url|anydata|anydataset|anytype|all_arguments|user_arguments|dba_objects|all_objects|user_objects|sys_objects|dba_source|all_source|user_source|myappadmin\.adduser)(\s|\.|\()]==],
            id = 100021,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/\*.+(\w|\W).+\*/]==],
            id = 100022,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[('|")[^-]*--]==],
            id = 100023,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[passthru(\s+)?\(]==],
            id = 100024,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[(chr|char|varchar|nvarchar)\(\d+\)]==],
            id = 100025,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[select @@?\w.*--]==],
            id = 100026,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[^['"][\s\<\>;-]]==],
            id = 100027,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[^/\*]==],
            id = 100028,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[select\s.+\sfrom \(]==],
            id = 100029,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[(and|or)\s.+\s+is\s+null]==],
            id = 100030,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[("'|'"|--)[\s\<\>;-]]==],
            id = 100031,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[\W1e309\W]==],
            id = 100032,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[;--\s]==],
            id = 100033,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[``]==],
            id = 100034,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[.*select.+from.+where.+]==],
            id = 100035,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[.*(select)?.+case.+when.+then]==],
            id = 100036,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[\Wsleep\W?\(\W?\d+\W?\)]==],
            id = 100037,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[.*<[- ~]{4,}>]==],
            id = 100038,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[</?(.+\W)?(address|area|article|aside|audio|base|br|bdi|bdo|blockquote|body|button|canvas|caption|cite|code|col|colgroup|command|data|datalist|del|details|dfn|div|embed|fieldset|figcaption|figure|footer|form|head|header|hgroup|html|iframe|img|input|ins|keygen|label|legend|link|main|map|mark|math|menu|meta|meter|nav|noscript|object|optgroup|option|output|param|pre|progress|ruby|samp|script|section|select|small|source|span|strong|style|summary|table|tbody|textarea|tfoot|thead|time|title|track|var|video|wbr)[\W]]==],
            id = 100039,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[javascript.*:]==],
            id = 100040,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[.*\W(function|alert|prompt|eval)\W?.*\(.*\).*]==],
            id = 100041,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[(shell:|\.fromcharcode)]==],
            id = 100042,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[\bon(abort|blur|change|click|dblclick|dragdrop|error|focus|keydown|keypress|keyup|load|mousedown|mousemove|mouseout|mouseover|mouseup|move|readystatechange|reset|resize|select|submit|unload)\b\W*?=]==],
            id = 100043,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[<!--]==],
            id = 100044,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[-moz-binding\:]==],
            id = 100045,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[(|'|"|=|;)res\:(.*)?(\|/)]==],
            id = 100046,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[\.(call|apply)\W.*(this|window|document|name|body|location)]==],
            id = 100047,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[('|")>.*<!]==],
            id = 100048,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[<\s*(a|img|script)\s+(href|src)]==],
            id = 100049,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[<\s*(\w+).*\s+(href|src)\s*=]==],
            id = 100050,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[(\\.\.){2,}]==],
            id = 100051,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[^/(-|\.|~)]==],
            id = 100052,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[^/[\(\)]]==],
            id = 100053,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[^/\{\d+\}]==],
            id = 100054,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[^///]==],
            id = 100055,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[^/(\\.){3,}]==],
            id = 100056,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[^/about:.+]==],
            id = 100057,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[^/(~|_)?admin((_|-).*)?/]==],
            id = 100058,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[^/admisapi/]==],
            id = 100059,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/adodb/]==],
            id = 100060,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/advwebadmin/]==],
            id = 100061,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/adxmlrpc.php]==],
            id = 100062,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/db/mysql/]==],
            id = 100063,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/apache/]==],
            id = 100064,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/.*\.inc\.php.*]==],
            id = 100065,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[~.+\.(bak|copy|old|swp|tmp.*)]==],
            id = 100066,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/win.ini]==],
            id = 100067,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/passwd]==],
            id = 100068,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/f?cgi-bin/_?(admin|config|include|sh|shell|global)]==],
            id = 100069,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/f?cgi-bin/.+\.(ini|dat|dll|pl|exe|asp|xml|cgi|mdb|dat|php|php3|perl|aspx|html|bz2|7z|bz2|gz|jar|rar|tar|tgz|war|z|zip)]==],
            id = 100070,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/conf/ssl/]==],
            id = 100071,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/crypto/]==],
            id = 100072,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[\:\:\$DATA]==],
            id = 100073,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/fbsd/]==],
            id = 100074,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/hsx.cgi]==],
            id = 100075,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/ht/(bin|docs)]==],
            id = 100076,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/\.htaccess]==],
            id = 100077,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/iis(admin|admpwd|protect|samples)]==],
            id = 100078,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/inc/.+.php]==],
            id = 100080,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/info2www]==],
            id = 100081,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/info.dat]==],
            id = 100082,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/.git/]==],
            id = 100083,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/gitweb]==],
            id = 100084,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/mail/(admin|atmail)]==],
            id = 100085,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/mailbox.php3]==],
            id = 100086,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/mail(file)?.cgi]==],
            id = 100087,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/mailgu(ard|st)/]==],
            id = 100088,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/mail/(inc|src)/]==],
            id = 100089,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/maillist/]==],
            id = 100090,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/mail_log_files/]==],
            id = 100091,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/mailnews.cgi]==],
            id = 100092,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/mail\.php]==],
            id = 100093,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/mailpost.exe]==],
            id = 100094,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/mail(man|root|scanner|-secure|secure|server|view|watch)]==],
            id = 100095,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/_maincfgret.cgi]==],
            id = 100096,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/main.cgi]==],
            id = 100097,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/main/inc/lib/]==],
            id = 100098,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/nettracker/]==],
            id = 100099,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/netutils]==],
            id = 100100,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/_old/]==],
            id = 100101,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/old_files/]==],
            id = 100102,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/oldfiles/]==],
            id = 100103,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/old/wp-admin/]==],
            id = 100104,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/_vti]==],
            id = 100105,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[^/']==],
            id = 100106,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[^/admin]==],
            id = 100107,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[\\\.]==],
            id = 100109,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[([$@{}()\[\]].*){8,}]==],
            id = 100110,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[^[\[\]$;."(),'`{}]{7,}$]==],
            id = 100111,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/\.(\w|\.|-)+/?]==],
            id = 100112,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[%20onload=]==],
            id = 100113,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[%3e%3c]==],
            id = 100114,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[\);}}--></script><script]==],
            id = 100115,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[../../../../../]==],
            id = 100116,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/.../.././../]==],
            id = 100117,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/.htaccess]==],
            id = 100118,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[//../..//..]==],
            id = 100119,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/Acunetix]==],
            id = 100120,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/acunetix]==],
            id = 100121,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/ppim/email/root.email]==],
            id = 100122,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/ppim/password.dat]==],
            id = 100123,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/var/www/]==],
            id = 100124,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/~1/]==],
            id = 100125,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/~admin/]==],
            id = 100126,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/~log/]==],
            id = 100127,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/~nobody/etc/passwd]==],
            id = 100128,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/~root/]==],
            id = 100129,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/~stats/]==],
            id = 100130,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/~webstats/]==],
            id = 100131,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[/~wsdocs/]==],
            id = 100132,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[appscan_fingerprint]==],
            id = 100133,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[boot.ini]==],
            id = 100134,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[cmd.exe]==],
            id = 100135,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[code=phold]==],
            id = 100136,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[document.cookie]==],
            id = 100137,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[etc/passwd]==],
            id = 100138,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[global.asa]==],
            id = 100139,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[htaccess]==],
            id = 100140,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[modtest]==],
            id = 100141,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[nessustest]==],
            id = 100142,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[php_info()]==],
            id = 100143,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[phpinfo()]==],
            id = 100144,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[rfi?..]==],
            id = 100145,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[system.ini]==],
            id = 100146,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[windows/win.ini]==],
            id = 100147,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[Xx<XaXaXXaXaX>xX]==],
            id = 100148,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[ & dir]==],
            id = 100149,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[';",\)`]==],
            id = 100150,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[(&&|\|\||;|`)\s*?(arch|ash|awk|base64|basename|bash|bc|bsh|bunzip2|cat|chcon|chgrp|chmod|chown|chroot|cjpeg|cksum|clear|comm|configure|cp|cpio|csh|csplit|curl|cut|date|dc|dd|df|diff|diff3|dig|dir|dircolors|dirname|djpeg|dmesg|dnsdomainname|doexec|domainname|dos2unix|du|dumpkeys|echo|ed|egrep|eject|elinks|env|ex|expand|expr|ext|factor|false|fdisk|fgrep|find|finger|fixps|fmt|fold|free|gawk|grep|groups|gtar|gunzip|gzip|halt|hdparm|head|hell|history|hostid|hostname|httpd|id|identify|ifconfig|igawk|install|ipcalc|join|kbd_mode|kill|last|lastlog|link|links|ln|loadkeys|locate|login|logname|look|ls|lsmod|lynx|mac2unix|mail|man|manweb|md5sum|mdu|mkdir|mkfifo|mkfs|mknod|mktemp|more|mount|mt|mtr|mv|namei|nano|nc|ncftp|nedit-nc|netstat|nice|nisdomainname|nl|nohup|nslookup|od|paste|pathchk|pdf2dsc|pdf2ps|pdfinfo|pdftotext|perl|pgawk|pico|pine|ping|ping6|pinky|pr|printenv|printf|ps|ps2ascii|ps2epsi|ps2frag|ps2pdf|ps2pdf12|ps2pdf13|ps2pdf14|ps2pdfwr|ps2pk|ps2ps|psbook|ptx|pwd|quota|readelf|readlink|reboot|red|rename|resize|rm|rmdir|rpm|runcon|rundig|rvi|sed|seq|gid|serial|uid|setfont|sfdisk|sftp|sh|sha1sum|sha224sum|sha256sum|sha384sum|sha512sum|shred|shuf|sleep|slocate|sort|split|ssh|stat|stty|stty cooked|stty raw|su|sum|switchdesk|sync|tac|tail|tar|tcsh|tee|telnet|test|time|timeout|tr|tracepath|tracepath6|traceroute|traceroute6|tree|true|truncate|tsort|tty|umask|umount|uname|unexpand|unicode_start|unicode_stop|uniq|unlink|ungid|unuid|untar|unzip|updatedb|uptime|useradd|users|usleep|vdir|viwc|wget|is|whereis|which|who|whoami|whois|xinit|xpdf|xrandr|yes|ypdomainname|zcat|zip|zipinfo)(\s|;|&|`|#|$)]==],
            id = 100151,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[(arch|ash|awk|base64|basename|bash|bc|bsh|bunzip2|cat|chcon|chgrp|chmod|chown|chroot|cjpeg|cksum|clear|comm|configure|cp|cpio|csh|csplit|curl|cut|date|dc|dd|df|diff|diff3|dig|dir|dircolors|dirname|djpeg|dmesg|dnsdomainname|doexec|domainname|dos2unix|du|dumpkeys|echo|ed|egrep|eject|elinks|env|ex|expand|expr|ext|factor|false|fdisk|fgrep|find|finger|fixps|fmt|fold|free|gawk|grep|groups|gtar|gunzip|gzip|halt|hdparm|head|hell|history|hostid|hostname|httpd|id|identify|ifconfig|igawk|install|ipcalc|join|kbd_mode|kill|last|lastlog|link|links|ln|loadkeys|locate|login|logname|look|ls|lsmod|lynx|mac2unix|mail|man|manweb|md5sum|mdu|mkdir|mkfifo|mkfs|mknod|mktemp|more|mount|mt|mtr|mv|namei|nano|nc|ncftp|nedit-nc|netstat|nice|nisdomainname|nl|nohup|nslookup|od|paste|pathchk|pdf2dsc|pdf2ps|pdfinfo|pdftotext|perl|pgawk|pico|pine|ping|ping6|pinky|pr|printenv|printf|ps|ps2ascii|ps2epsi|ps2frag|ps2pdf|ps2pdf12|ps2pdf13|ps2pdf14|ps2pdfwr|ps2pk|ps2ps|psbook|ptx|pwd|quota|readelf|readlink|reboot|red|rename|resize|rm|rmdir|rpm|runcon|rundig|rvi|sed|seq|gid|serial|uid|setfont|sfdisk|sftp|sh|sha1sum|sha224sum|sha256sum|sha384sum|sha512sum|shred|shuf|sleep|slocate|sort|split|ssh|stat|stty|stty cooked|stty raw|su|sum|switchdesk|sync|tac|tail|tar|tcsh|tee|telnet|test|time|timeout|tr|tracepath|tracepath6|traceroute|traceroute6|tree|true|truncate|tsort|tty|umask|umount|uname|unexpand|unicode_start|unicode_stop|uniq|unlink|ungid|unuid|untar|unzip|updatedb|uptime|useradd|users|usleep|vdir|viwc|wget|is|whereis|which|who|whoami|whois|xinit|xpdf|xrandr|yes|ypdomainname|zcat|zip|zipinfo)\s+(-+[a-z]+)]==],
            id = 100152,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[(&&|\|\||;|`)\s*?(arch|ash|awk|base64|basename|bash|bc|bsh|bunzip2|cat|chcon|chgrp|chmod|chown|chroot|cjpeg|cksum|clear|comm|configure|cp|cpio|csh|csplit|curl|cut|date|dc|dd|df|diff|diff3|dig|dir|dircolors|dirname|djpeg|dmesg|dnsdomainname|doexec|domainname|dos2unix|du|dumpkeys|echo|ed|egrep|eject|elinks|env|ex|expand|expr|ext|factor|false|fdisk|fgrep|find|finger|fixps|fmt|fold|free|gawk|grep|groups|gtar|gunzip|gzip|halt|hdparm|head|hell|history|hostid|hostname|httpd|id|identify|ifconfig|igawk|install|ipcalc|join|kbd_mode|kill|last|lastlog|link|links|ln|loadkeys|locate|login|logname|look|ls|lsmod|lynx|mac2unix|mail|man|manweb|md5sum|mdu|mkdir|mkfifo|mkfs|mknod|mktemp|more|mount|mt|mtr|mv|namei|nano|nc|ncftp|nedit-nc|netstat|nice|nisdomainname|nl|nohup|nslookup|od|paste|pathchk|pdf2dsc|pdf2ps|pdfinfo|pdftotext|perl|pgawk|pico|pine|ping|ping6|pinky|pr|printenv|printf|ps|ps2ascii|ps2epsi|ps2frag|ps2pdf|ps2pdf12|ps2pdf13|ps2pdf14|ps2pdfwr|ps2pk|ps2ps|psbook|ptx|pwd|quota|readelf|readlink|reboot|red|rename|resize|rm|rmdir|rpm|runcon|rundig|rvi|sed|seq|gid|serial|uid|setfont|sfdisk|sftp|sh|sha1sum|sha224sum|sha256sum|sha384sum|sha512sum|shred|shuf|sleep|slocate|sort|split|ssh|stat|stty|stty cooked|stty raw|su|sum|switchdesk|sync|tac|tail|tar|tcsh|tee|telnet|test|time|timeout|tr|tracepath|tracepath6|traceroute|traceroute6|tree|true|truncate|tsort|tty|umask|umount|uname|unexpand|unicode_start|unicode_stop|uniq|unlink|ungid|unuid|untar|unzip|updatedb|uptime|useradd|users|usleep|vdir|viwc|wget|is|whereis|which|who|whoami|whois|xinit|xpdf|xrandr|yes|ypdomainname|zcat|zip|zipinfo)\s+((-+[a-z]+)|(/\w){2,})]==],
            id = 100153,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[(exec|popen|system|os\.command|shell|escapeshellcmd)\(.*\)]==],
            id = 100154,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[(arch|ash|awk|base64|basename|bash|bc|bsh|bunzip2|cat|chcon|chgrp|chmod|chown|chroot|cjpeg|cksum|clear|comm|configure|cp|cpio|csh|csplit|curl|cut|date|dc|dd|df|diff|diff3|dig|dir|dircolors|dirname|djpeg|dmesg|dnsdomainname|doexec|domainname|dos2unix|du|dumpkeys|echo|ed|egrep|eject|elinks|env|ex|expand|expr|ext|factor|false|fdisk|fgrep|find|finger|fixps|fmt|fold|free|gawk|grep|groups|gtar|gunzip|gzip|halt|hdparm|head|hell|history|hostid|hostname|httpd|id|identify|ifconfig|igawk|install|ipcalc|join|kbd_mode|kill|last|lastlog|link|links|ln|loadkeys|locate|login|logname|look|ls|lsmod|lynx|mac2unix|mail|man|manweb|md5sum|mdu|mkdir|mkfifo|mkfs|mknod|mktemp|more|mount|mt|mtr|mv|namei|nano|nc|ncftp|nedit-nc|netstat|nice|nisdomainname|nl|nohup|nslookup|od|paste|pathchk|pdf2dsc|pdf2ps|pdfinfo|pdftotext|perl|pgawk|pico|pine|ping|ping6|pinky|pr|printenv|printf|ps|ps2ascii|ps2epsi|ps2frag|ps2pdf|ps2pdf12|ps2pdf13|ps2pdf14|ps2pdfwr|ps2pk|ps2ps|psbook|ptx|pwd|quota|readelf|readlink|reboot|red|rename|resize|rm|rmdir|rpm|runcon|rundig|rvi|sed|seq|gid|serial|uid|setfont|sfdisk|sftp|sh|sha1sum|sha224sum|sha256sum|sha384sum|sha512sum|shred|shuf|sleep|slocate|sort|split|ssh|stat|stty|stty cooked|stty raw|su|sum|switchdesk|sync|tac|tail|tar|tcsh|tee|telnet|test|time|timeout|tr|tracepath|tracepath6|traceroute|traceroute6|tree|true|truncate|tsort|tty|umask|umount|uname|unexpand|unicode_start|unicode_stop|uniq|unlink|ungid|unuid|untar|unzip|updatedb|uptime|useradd|users|usleep|vdir|viwc|wget|is|whereis|which|who|whoami|whois|xinit|xpdf|xrandr|yes|ypdomainname|zcat|zip|zipinfo)(\s+(-|&&|\|\||;|>|<).*){2,}[ -~]]==],
            id = 100155,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[;.*\$\((arch|ash|awk|base64|basename|bash|bc|bsh|bunzip2|cat|chcon|chgrp|chmod|chown|chroot|cjpeg|cksum|clear|comm|configure|cp|cpio|csh|csplit|curl|cut|date|dc|dd|df|diff|diff3|dig|dir|dircolors|dirname|djpeg|dmesg|dnsdomainname|doexec|domainname|dos2unix|du|dumpkeys|echo|ed|egrep|eject|elinks|env|ex|expand|expr|ext|factor|false|fdisk|fgrep|find|finger|fixps|fmt|fold|free|gawk|grep|groups|gtar|gunzip|gzip|halt|hdparm|head|hell|history|hostid|hostname|httpd|id|identify|ifconfig|igawk|install|ipcalc|join|kbd_mode|kill|last|lastlog|link|links|ln|loadkeys|locate|login|logname|look|ls|lsmod|lynx|mac2unix|mail|man|manweb|md5sum|mdu|mkdir|mkfifo|mkfs|mknod|mktemp|more|mount|mt|mtr|mv|namei|nano|nc|ncftp|nedit-nc|netstat|nice|nisdomainname|nl|nohup|nslookup|od|paste|pathchk|pdf2dsc|pdf2ps|pdfinfo|pdftotext|perl|pgawk|pico|pine|ping|ping6|pinky|pr|printenv|printf|ps|ps2ascii|ps2epsi|ps2frag|ps2pdf|ps2pdf12|ps2pdf13|ps2pdf14|ps2pdfwr|ps2pk|ps2ps|psbook|ptx|pwd|quota|readelf|readlink|reboot|red|rename|resize|rm|rmdir|rpm|runcon|rundig|rvi|sed|seq|gid|serial|uid|setfont|sfdisk|sftp|sh|sha1sum|sha224sum|sha256sum|sha384sum|sha512sum|shred|shuf|sleep|slocate|sort|split|ssh|stat|stty|stty cooked|stty raw|su|sum|switchdesk|sync|tac|tail|tar|tcsh|tee|telnet|test|time|timeout|tr|tracepath|tracepath6|traceroute|traceroute6|tree|true|truncate|tsort|tty|umask|umount|uname|unexpand|unicode_start|unicode_stop|uniq|unlink|ungid|unuid|untar|unzip|updatedb|uptime|useradd|users|usleep|vdir|viwc|wget|is|whereis|which|who|whoami|whois|xinit|xpdf|xrandr|yes|ypdomainname|zcat|zip|zipinfo).*\)]==],
            id = 100156,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[[A-Za-z]\:.+\.(exe|bat|cmd|dll)]==],
            id = 100157,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[\w\.(exe|bat|cmd|dll|sh|bash)($|(\?.*))]==],
            id = 100158,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[(\s|"|')(jscript|onsubmit|copyparentfolder|document|javascript|meta|onchange|onmove|onkeydown|onkeyup|activexobject|onerror|onmouseup|ecmascript|bexpression|onmouseover|vbscript:|<!\[cdata\[|http:|.innerhtml|settimeout|shell:|onabort|asfunction:|onkeypress|onmousedown|onclick|.fromcharcode|background-image:|x-javascript|ondragdrop|onblur|mocha:|javascript:|onfocus|lowsrc|getparentfolder|onresize|@import|alert|script|onselect|onmouseout|application|onmousemove|background|.execscript|livescript:|vbscript|getspecialfolder|.addimport|<iframe|onunload|createtextrange|<input|onload)(\s|=)]==],
            id = 100159,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[%3c.+%3e.+%3c%2f.+%3e]==],
            id = 100160,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
        {
            expression = [==[%3c.+%2f%3e]==],
            id = 100161,
            flags = {
                luahs.pattern_flags.HS_FLAG_CASELESS,
                luahs.pattern_flags.HS_FLAG_MULTILINE,
                luahs.pattern_flags.HS_FLAG_DOTALL,
            }
        },
    },
    mode = luahs.compile_mode.HS_MODE_VECTORED
}

scratch_object = hscandb:makeScratch()

function scan(hca_values)
    return hscandb:scan(hca_values,scratch_object)
end

