use hyperscan::*;

pub struct SigSet {
    regex_set : Option<hyperscan::BlockDatabase>,
    scratch: Option<Scratch>,
    pattern_list : Vec<Pattern>,
    id2user:  Vec<String>,
}


#[derive(Debug)]
pub enum SigSetError {
    RegexSetNotCompiled,
    RegexSetAlreadyCompiled,
    RegexCompileError(anyhow::Error),
 }

impl std::string::ToString for SigSetError {
    fn to_string(&self) -> String {
        match self {
            SigSetError::RegexSetAlreadyCompiled => "SigSet already compiled".to_string(),
            SigSetError::RegexSetNotCompiled => "SigSet not compiled".to_string(),
            SigSetError::RegexCompileError(_) => "Compilation error".to_string(),
        }
    }
}

impl SigSet {
    pub fn new() -> SigSet {
        SigSet {
            regex_set: None,
            scratch: None,
            pattern_list: Vec::new(),
            id2user: Vec::new(),
        }
    }

    pub fn add(&mut self, regex: String, user: String) -> Result<(),SigSetError> {
        match &self.regex_set {
            Some(_) => Err(SigSetError::RegexSetAlreadyCompiled),
            None => {
                match regex.parse::<Pattern>() {
                    Ok(pat) => {
                        self.id2user.push(user);
                        self.pattern_list.push(pat);
                        Ok(())
                    }
                    Err(x) => Err(SigSetError::RegexCompileError(x)),
                }
            }
        }
    }

    pub fn compile(&mut self) -> Result<(),SigSetError> {
        match &self.regex_set {
            Some(_) => Err(SigSetError::RegexSetAlreadyCompiled),
            None => {
                match hyperscan::Patterns::from(self.pattern_list.clone()).build() {
                    Ok(db) => {
                        self.scratch = Some(db.alloc_scratch().unwrap());
                        self.regex_set = Some(db);
                        Ok(())
                    },
                    Err(x) => Err(SigSetError::RegexCompileError(x)),
                }
            }
        }
    }

    pub fn clear(&mut self) {
        self.regex_set = None;
        self.scratch = None;
        self.pattern_list = Vec::new();
        self.id2user = Vec::new();
    }

    pub fn is_match(&self, s: &String) -> Result<bool,SigSetError> {
        match (&self.regex_set,&self.scratch) {
            (Some(rs),Some(scratch)) => match rs.scan(s, scratch, |_,_,_,_|{ Matching::Terminate}) {
                Ok(_) => Ok(false),
                _ => Ok(true)
            }
            _ => Err(SigSetError::RegexSetNotCompiled)
        }
    }

    pub fn is_match_id(&self, s: &String) -> Result<Option<&String>,SigSetError> {
        match (&self.regex_set,&self.scratch) {
            (Some(rs),Some(scratch)) => {
                let mut match_id: Option<usize> = None;
                match rs.scan(s, scratch, |id,_,_,_|{ match_id = Some(id as usize); Matching::Terminate}) { _ => {} }
                Ok(match_id.map(|x| &self.id2user[x]))
            }
            _ => Err(SigSetError::RegexSetNotCompiled),
        }
    }


    pub fn is_match_ids(&self, s: &String) -> Result<Vec<&String>,SigSetError> {
        match (&self.regex_set,&self.scratch) {
            (Some(rs),Some(scratch)) => {
                let mut match_ids: Vec<usize> = Vec::new();
                match rs.scan(s, scratch, |id,_,_,_|{ 
                    let uid: usize = id as usize;
                    match match_ids.last() {
                        Some(x) if *x == uid => {},
                        _ => match_ids.push(uid)
                    }
                    Matching::Continue
                }) { _ => {} };
                Ok(match_ids.iter().map(|x| &self.id2user[*x]).collect())
            }
            _ => Err(SigSetError::RegexSetNotCompiled),
        }
    }

}


#[cfg(test)]
mod tests {
    use super::*;

    macro_rules! s { ( $e:expr ) => ( ($e).to_string() ) }
    macro_rules! testT { ( $e:expr ) => { let r = ($e); println!("expect True: {:?}", r); assert!(r.unwrap()) } }
    macro_rules! testF { ( $e:expr ) => { let r = ($e); println!("expect False: {:?}", r); assert!(!r.unwrap()) } }
    macro_rules! testOk { ( $e:expr ) => { let r = ($e); println!("expect Ok: {:?}", r); assert!(r.is_ok()) } }
    macro_rules! testErr { ( $e:expr ) => { let r = ($e); println!("expect Err: {:?}", r); assert!(r.is_err()) } }
    macro_rules! testEq { ( $e:expr , $f:expr ) => { let r = ($e); println!("expect ${:?}: {:?}", ($f), r); assert!(r.unwrap() == ($f)) } }

    #[test]
    fn test_add() {
        let mut ss = SigSet::new();
        testOk!(ss.add(s!("^A+$"), s!("only As")));
        testOk!(ss.add(s!("^B+$"), s!("only Bs")));
        testOk!(ss.add(s!("^C+$"), s!("only Cs")));
    }
    #[test]
    fn test_compile() {
        let mut ss = SigSet::new();
        testOk!(ss.add(s!("^A+$"), s!("only As")));
        testOk!(ss.add(s!("^B+$"), s!("only Bs")));
        testOk!(ss.add(s!("^C+$"), s!("only Cs")));
        testOk!(ss.compile());
    }

    #[test]
    fn test_recompile() {
        let mut ss = SigSet::new();
        testOk!(ss.add(s!("^A+$"), s!("only As")));
        testOk!(ss.compile());
        testErr!(ss.compile());
    }

    #[test]
    fn test_add_err_after_compile() {
        let mut ss = SigSet::new();
        testOk!(ss.add(s!("^A+$"), s!("only As")));
        testOk!(ss.add(s!("^B+$"), s!("only Bs")));
        testOk!(ss.compile());
        testErr!(ss.add(s!("^C+$"), s!("only Cs")));
    }

    #[test]
    fn test_compile_err() {
        let mut ss = SigSet::new();
        testOk!(ss.add(s!("^A+$"), s!("only As")));
        testOk!(ss.add(s!("+[]+^B+$^"), s!("only Bs")));
        testErr!(ss.compile());
    }

    #[test]
    fn test_is_match() {
        let mut ss = SigSet::new();
        testOk!(ss.add(s!("^A+$"), s!("only As")));
        testOk!(ss.add(s!("^B+$"), s!("only Bs")));
        testOk!(ss.add(s!("^C+$"), s!("only Cs")));
        testOk!(ss.compile());
        testT!(ss.is_match(&s!("AAAAA")));
        testT!(ss.is_match(&s!("BBB")));
        testF!(ss.is_match(&s!("BBC")));
    }

    #[test]
    fn test_clear() {
        let mut ss = SigSet::new();
        testOk!(ss.add(s!("^A+$"), s!("only As")));
        testOk!(ss.compile());
        testT!(ss.is_match(&s!("AAAAA")));
        ss.clear();
        testErr!(ss.is_match(&s!("AAAAA")));
        testOk!(ss.add(s!("^B+$"), s!("only Bs")));
        testOk!(ss.compile());
        testF!(ss.is_match(&s!("AAAAA")));
        testT!(ss.is_match(&s!("BBB")));
    }

    #[test]
    fn test_match_id() {
        let mut ss = SigSet::new();
        testOk!(ss.add(s!("^A+$"), s!("only As")));
        testOk!(ss.add(s!("^B+$"), s!("only Bs")));
        testOk!(ss.add(s!("^C+$"), s!("only Cs")));
        testOk!(ss.compile());
        let r = ss.is_match_id(&s!("AAAAA"));
        assert!(r.unwrap().unwrap() == &s!("only As"));
        let r = ss.is_match_id(&s!("CCC"));
        assert!(r.unwrap().unwrap() == &s!("only Cs"));
        let r = ss.is_match_id(&s!("CADCC"));
        assert!(r.unwrap().is_none());
    }

    #[test]
    fn test_match_ids() {
        let mut ss = SigSet::new();
        testOk!(ss.add(s!("^A+"), s!("starts with As")));
        testOk!(ss.add(s!("B+$"), s!("ends with Bs")));
        testOk!(ss.add(s!("^C+$"), s!("only Cs")));
        testOk!(ss.compile());

        testEq!(ss.is_match_ids(&s!("AAAAA")),  vec!["starts with As"]);
        testEq!(ss.is_match_ids(&s!("AAAAABBBB")),  vec!["starts with As", "ends with Bs"]);
        testEq!(ss.is_match_ids(&s!("CAAAAABBBBCC")),  vec![] as Vec<&String>);
    }


}
