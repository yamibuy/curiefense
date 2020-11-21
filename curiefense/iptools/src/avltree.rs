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
