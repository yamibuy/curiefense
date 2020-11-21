use std::cmp::Ordering;


type Tree<T> = Option<Box<Node<T>>>;

#[derive(Debug)]
struct Node<T: Ord> {
    key    : T,
    height : i32,
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

        let mut p_tree = &mut self.root;
        while let Some(p_node) = p_tree {
            match p_node.key.cmp(&key) {
                Ordering::Less => p_tree = &mut p_node.right,
                Ordering::Greater => p_tree = &mut p_node.left,
                Ordering::Equal => { return false; },
            }
        }
        *p_tree = Some(Box::new(Node::new(key)));
        self.size += 1;
        true
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

    pub fn len(& self) -> usize {
        self.size
    }
}

impl<T> Node<T> where T:Ord {
    pub fn new(key: T) -> Node<T> {
        Node {
            key: key,
            height: 0,
            left: None,
            right: None,
        }
    }
}
