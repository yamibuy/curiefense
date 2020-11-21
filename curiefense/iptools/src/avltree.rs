use std::cmp::Ordering;
use std::cmp::max;

type Tree<T> = Option<Box<Node<T>>>;

#[derive(Debug)]
struct Node<T: Ord> {
    key    : T,
    height : isize,
    left   : Tree<T>,
    right  : Tree<T>,
}

#[derive(Debug)]
pub struct AVLTreeSet<T : Ord> {
    root : Tree<T>,
    size : usize,
}


impl<T> AVLTreeSet<T> where T:Ord {
    pub fn new() -> AVLTreeSet<T> {
        AVLTreeSet { root: None, size: 0 }
    }

    pub fn insert(& mut self, key: T) -> bool {
        fn ins<T:Ord>(p_tree: &mut Tree<T>, key: T) -> (bool,isize) {
            match p_tree {
                None => { *p_tree = Some(Box::new(Node::new(key))); (true,1) }
                Some(p_node) =>
                    match p_node.key.cmp(&key) {
                        Ordering::Less => {
                            let (i,h) = ins(& mut p_node.right, key);
                            p_node.height = max(p_node.height, h+1);
                            (i,p_node.height)
                        },
                        Ordering::Greater => {
                            let (i,h) = ins(& mut p_node.left, key);
                            p_node.height = max(p_node.height, h+1);
                            (i,p_node.height)
                        },
                        Ordering::Equal => { return (false,p_node.height); },
                    }
            }
        }
        let (inserted,_) = ins(& mut self.root, key);
        if inserted { self.size += 1};
        inserted
    }

    pub fn contains(&self, key: &T) -> bool {
        let mut p_tree = &self.root;
        while let Some(p_node) = p_tree {
            match p_node.key.cmp(&key) {
                Ordering::Less => p_tree = &p_node.right,
                Ordering::Greater => p_tree = &p_node.left,
                Ordering::Equal => { return true; },
            }
        }
        false
    }

    pub fn custom_contains(&self, key: &T, compare: fn(&T,&T)-> Ordering) -> bool {
        let mut p_tree = &self.root;
        while let Some(p_node) = p_tree {
            match compare(&p_node.key, &key) {
                Ordering::Less => p_tree = &p_node.right,
                Ordering::Greater => p_tree = &p_node.left,
                Ordering::Equal => { return true; },
            }
        }
        false
    }

    pub fn height(& self) -> usize {
        match &self.root {
            None => 0,
            Some(node) => node.height as usize
        }
    }

    pub fn len(& self) -> usize {
        self.size
    }
}

impl<T> Node<T> where T:Ord {
    pub fn new(key: T) -> Node<T> {
        Node {
            key: key,
            height: 1,
            left: None,
            right: None,
        }
    }
}




#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_insert() {
        let mut t = AVLTreeSet::new();
        assert!(!t.contains(&2));
        assert!(t.insert(2));
        assert!(t.contains(&2));
        assert!(!t.insert(2));
        assert!(!t.contains(&3));
        assert!(t.insert(3));
        assert!(t.contains(&3));
        assert!(!t.contains(&4));
    }
    #[test]
    fn test_len() {
        let mut t = AVLTreeSet::new();
        assert!(t.len() == 0);
        assert!(t.insert(&1));
        assert!(t.len() == 1);
        assert!(t.insert(&2));
        assert!(t.len() == 2);
        assert!(!t.insert(&1));
        assert!(t.len() == 2);
    }
    #[test]
    fn test_height() {
        let mut t = AVLTreeSet::new();
        assert!(t.height() == 0);
        assert!(t.insert(&2));
        assert!(t.height() == 1);
        assert!(t.insert(&3));
        assert!(t.height() == 2);
        assert!(t.insert(&1));
        assert!(t.height() == 2);
        assert!(t.insert(&0));
        assert!(t.height() == 3);
        assert!(t.insert(&4));
        assert!(t.height() == 3);
        assert!(t.insert(&5));
        assert!(t.height() == 4);
    }
}
