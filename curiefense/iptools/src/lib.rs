#[macro_use]
extern crate mlua_derive;

use mlua::prelude::*;
use cidr::AnyIpCidr;
use std::str::FromStr;
use std::cmp::Ordering;
use md5;
use std::net::IpAddr;

pub mod avltree;
use avltree::AVLTreeMap;

pub mod sigset;
use sigset::{SigSet,SigSetError};

#[derive(Debug)]
struct IPSet (AVLTreeMap<AnyIpCidr,String>);

//////////////// IP SET ////////////////

fn cmp(net:&AnyIpCidr, ip:&AnyIpCidr) -> Ordering {
    let eq = match (ip.first_address(), ip.last_address(), net.first_address(), net.last_address()) {
        (Some(kf), Some(kl), Some(vf), Some(vl)) => ((kf <= vl) && (vf <= kl)),
        (_, _, None, None) => true,
        (None, None, Some(_), Some(_)) => true,
        (_,_,_,_) => panic!("internal error")
    };
    if eq {
        return Ordering::Equal
    }
    else {
        net.cmp(ip)
    }
}


impl IPSet {
    pub fn new() -> IPSet {
        IPSet(AVLTreeMap::new())
    }

    pub fn contains(&self, key: &AnyIpCidr) -> bool {
        self.0.contains_custom(key, cmp)
   }

    pub fn get(&self, key: &AnyIpCidr) -> Option<&String> {
        self.0.get_custom(key, cmp)
   }

    pub fn len(&self) -> usize {
        self.0.len()
    }

    pub fn insert(&mut self, key: AnyIpCidr, value: String) -> bool {
        self.0.insert(key, value)
    }
}


impl mlua::UserData for IPSet {
    fn add_methods<'lua, M: mlua::UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("len",
                           |_, this:&IPSet, _:()| {
                               Ok(this.len()) 
                           }
        );
        methods.add_method("contains",
                           |_, this:&IPSet, value:String| {
                               match AnyIpCidr::from_str(&value) {
                                   Ok(a) => Ok(Some(this.contains(&a))),
                                   Err(_) => Ok(None),
                               }
                           }
        );
        methods.add_method("get",
                           |_, this:&IPSet, value:String| {
                               match AnyIpCidr::from_str(&value) {
                                   Ok(a) => {
                                       match this.get(&a) {
                                           Some(v) => Ok(Some(v.clone())),
                                           None => Ok(None),
                                       }
                                   },
                                   Err(_) => Ok(None)
                               }
                           }
        );
        methods.add_method_mut("add",
                               |_, this:&mut IPSet, (key,value): (String,String)| {
                                   match AnyIpCidr::from_str(&key) {
                                       Ok(k) => Ok(Some(this.insert(k, value))),
                                       Err(_) => Ok(None),
                                   }
                               }
        );
    }
}



fn new_ip_set(_: &Lua, _:()) -> LuaResult<IPSet> {
    let ipset = IPSet::new();
    Ok(ipset)
}


//////////////// SIG SET ////////////////

fn new_sig_set(_: &Lua, _:()) -> LuaResult<SigSet> {
    Ok(SigSet::new())
}


impl Into<mlua::Error> for SigSetError {
    fn into(self) -> mlua::Error {
        mlua::Error::RuntimeError(self.to_string())
    }
}

impl mlua::UserData for SigSet {
    fn add_methods<'lua, M: mlua::UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut("add",
                           |_, this:&mut SigSet, (r,i):(String, String)| {
                               match this.add(r,i) {
                                   Ok(_) => Ok(()),
                                   Err(x) => Err(x.into()),
                               }
                           }
        );
        methods.add_method_mut("compile",
                           |_, this:&mut SigSet, _:()| {
                               match this.compile() {
                                   Ok(_) => Ok(()),
                                   Err(x) => Err(x.into()),
                               }
                           }
        );
        methods.add_method_mut("clear",
                               |_, this:&mut SigSet, _:()| {
                                   this.clear();
                                   Ok(())
                               }
        );
        methods.add_method("is_match",
                           |_, this:&SigSet, m:String| {
                               match this.is_match(&m) {
                                   Ok(res) => Ok(res),
                                   Err(x) => Err(x.into()),
                               }
                           }
        );
        methods.add_method("is_match_id",
                           |_, this:&SigSet, m:String| {
                               match this.is_match_id(&m) {
                                   Ok(res) => match res {
                                       None => Ok(None),
                                       Some(x) => Ok(Some(x.clone())),
                                   },
                                   Err(x) => Err(x.into()),
                               }
                           }
        );
        methods.add_method("is_match_ids",
                           |lua:&Lua, this:&SigSet, m:String| {
                               match this.is_match_ids(&m) {
                                   Ok(res) => {
                                       let tab = lua.create_table()?;
                                       for (i,&r) in res.iter().enumerate() {
                                           tab.set(i,r.clone())?;
                                       };
                                       Ok(tab)
                                   },
                                   Err(x) => Err(x.into()),
                               }
                           }
        );
    }
}

//////////////// MOD HASH ////////////////

fn modhash(_: &Lua, (val,m):(String,u32)) -> LuaResult<Option<u32>> {
    let digest = md5::compute(val);

    let res = match m {
        0 => None,
        m => {
            let h:u128 = u128::from_be_bytes(*digest);
            Some((h % (m as u128)) as u32)
        },
    };
    Ok(res)
}

//////////////// IP TO NUM ////////////////


fn iptonum(_: &Lua, ip:String) -> LuaResult<Option<String>> {
    match IpAddr::from_str(&ip) {
        Ok(r) => match r {
            IpAddr::V4(a) => Ok(Some(u32::from_be_bytes(a.octets()).to_string())),
            IpAddr::V6(a) => Ok(Some(u128::from_be_bytes(a.octets()).to_string())),
        },
        Err(_) => Ok(None)
    }
}


/////////////////////////////////////////


#[lua_module]
fn iptools(lua: &Lua) -> LuaResult<LuaTable> {
    let exports = lua.create_table()?;
    exports.set("new_ip_set", lua.create_function(new_ip_set)?)?;
    exports.set("new_sig_set", lua.create_function(new_sig_set)?)?;
    exports.set("modhash", lua.create_function(modhash)?)?;
    exports.set("iptonum", lua.create_function(iptonum)?)?;
    Ok(exports)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_ipset() {
        let mut ipset= IPSet::new();

        let ip1 = ["1.2.3.0/24", "1.1.1.1/32", "192.168.8.0/24","10.0.0.0/8"];
        let ip2 = ["192.168.8.24", "192.168.0.0/16", "192.168.8.64/29", "1.2.2.0/23", "10.1.2.3", "10.0.0.0/7","0.0.0.0/0"];
        let ip3 = ["1.2.4.0/24", "1.1.1.2/32", "192.168.7.0/24", "2.0.0.0/8"];

        for n in ip1.iter() {
            let a = AnyIpCidr::from_str(&n).unwrap();
            println!("Inserting {:?}",a);
            ipset.0.insert(a,"hello".to_string());
        }
        assert!(ipset.len() == ip1.len());


        for n in ip1.iter() {
            let a = AnyIpCidr::from_str(&n).unwrap();
            println!("Testing {:?}",a);
            assert!(ipset.contains(&a));
        }

        for n in ip2.iter() {
            let a = AnyIpCidr::from_str(&n).unwrap();
            println!("Testing {:?}",a);
            assert!(ipset.contains(&a));
        }

        for n in ip3.iter() {
            let a = AnyIpCidr::from_str(&n).unwrap();
            println!("Testing {:?}",a);
            assert!(!ipset.contains(&a));
        }
    }
}
