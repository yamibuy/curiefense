use std::cmp::Ordering;
use std::cmp::max;
use core::mem::swap;

type Tree<K,V> = Option<Box<Node<K,V>>>;

#[derive(Debug)]
struct Node<K: Ord,V> {
    key    : K,
    value  : V,
    height : isize,
    left   : Tree<K,V>,
    right  : Tree<K,V>,
}

#[derive(Debug)]
pub struct AVLTreeMap<K : Ord,V> {
    root : Tree<K,V>,
    size : usize,
}


impl<K,V> AVLTreeMap<K,V> where K:Ord {
    pub fn new() -> AVLTreeMap<K,V> {
        AVLTreeMap { root: None, size: 0 }
    }

    pub fn insert(& mut self, key: K, value: V) -> bool {

        fn ins<K:Ord,V>(p_tree: &mut Tree<K,V>, key: K, value: V) -> (bool,isize) {
            match p_tree {
                None => { *p_tree = Some(Box::new(Node::new(key, value))); (true,1) }
                Some(p_node) =>
                    match p_node.key.cmp(&key) {
                        Ordering::Less => {
                            let (i,h) = ins(& mut p_node.right, key, value);
                            p_node.height = max(p_node.height, h+1);
                            p_node.rebalance();
                            (i,p_node.height)
                        },
                        Ordering::Greater => {
                            let (i,h) = ins(& mut p_node.left, key, value);
                            p_node.height = max(p_node.height, h+1);
                            p_node.rebalance();
                            (i,p_node.height)
                        },
                        Ordering::Equal => { return (false,p_node.height); },
                    }
            }
        }
        let (inserted,_) = ins(& mut self.root, key, value);
        if inserted { self.size += 1};
        inserted
    }

    pub fn get(&self, key: &K) -> Option<&V> {
        let mut p_tree = &self.root;
        while let Some(p_node) = p_tree {
            match p_node.key.cmp(&key) {
                Ordering::Less => p_tree = &p_node.right,
                Ordering::Greater => p_tree = &p_node.left,
                Ordering::Equal => { return Some(&p_node.value); },
            }
        }
        None
    }

    pub fn contains(&self, key: &K) -> bool {
        self.get(key).is_some()
    }

    pub fn get_custom(&self, key: &K, compare: fn(&K,&K)-> Ordering) -> Option<&V> {
        let mut p_tree = &self.root;
        while let Some(p_node) = p_tree {
            match compare(&p_node.key, &key) {
                Ordering::Less => p_tree = &p_node.right,
                Ordering::Greater => p_tree = &p_node.left,
                Ordering::Equal => { return Some(&p_node.value); },
            }
        }
        None
    }

    pub fn contains_custom(&self, key: &K, compare: fn(&K,&K)-> Ordering) -> bool {
        self.get_custom(key, compare).is_some()
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

impl<K,V> Node<K,V> where K:Ord {
    pub fn new(key: K, value: V) -> Node<K,V> {
        Node {
            key: key,
            value: value,
            height: 1,
            left: None,
            right: None,
        }
    }

    fn height_left(&self) -> isize {
        match &self.left {
            None => 0,
            Some(node) => node.height,
        }
    }

    fn height_right(&self) -> isize {
        match &self.right {
            None => 0,
            Some(node) => node.height,
        }
    }

    fn update_height(&mut self) {
        self.height = max(self.height_left(), self.height_right())+1
    }


    fn balance_factor(&self) -> isize {
        self.height_right() - self.height_left()
    }

    fn rebalance(&mut self) -> bool {
        match self.balance_factor() {
            -1|0|1 => false,
            -2 => self.rotate_right(),
            2 => self.rotate_left(),
            _ => panic!("Internal error. AVLTree balance factor out of [-2;2]"),
        }
    }


    //      D          B
    //     / \        / \
    //    B   E  =>  A   D
    //   / \            / \
    //  A   C          C   E
    fn rotate_right(&mut self) -> bool {
        if self.left.is_none() {
            return false;
        }
        let mut btree = self.left.take();
        let mut bnode = btree.as_mut().unwrap();
        let atree = bnode.left.take();
        let ctree = bnode.right.take();
        let etree = self.right.take();

        // D becomes B and B becomes D
        swap(&mut self.key, &mut bnode.key);
        swap(&mut self.value, &mut bnode.value);

        bnode.left = ctree;
        bnode.right = etree;
        bnode.update_height();

        self.left = atree;
        self.right = btree;

        self.update_height();
        true
    }


    //     B            D
    //    / \          / \
    //   A   D   =>   B   E
    //      / \      / \
    //     C   E    A   C
    fn rotate_left(&mut self) -> bool {
        if self.right.is_none() {
            return false;
        }
        let mut dtree = self.right.take();
        let mut dnode = dtree.as_mut().unwrap();
        let ctree = dnode.left.take();
        let etree = dnode.right.take();
        let atree = self.right.take();

        // D becomes B and B becomes D
        swap(&mut self.key, &mut dnode.key); 
        swap(&mut self.value, &mut dnode.value);

        dnode.right = ctree;
        dnode.left = atree;
        dnode.update_height();

        self.right = etree;
        self.left = dtree;
        self.update_height();
        true
    }

}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_insert() {
        let mut t = AVLTreeMap::new();
        assert!(!t.contains(&2));
        assert!(t.insert(2, "hello"));
        assert!(t.contains(&2));
        assert!(!t.insert(2, "hello"));
        assert!(!t.contains(&3));
        assert!(t.insert(3, "hello"));
        assert!(t.contains(&3));
        assert!(!t.contains(&4));
    }
    #[test]
    fn test_len() {
        let mut t = AVLTreeMap::new();
        assert!(t.len() == 0);
        assert!(t.insert(&1, "hello 1"));
        assert!(t.len() == 1);
        assert!(t.insert(&2, "hello 2"));
        assert!(t.len() == 2);
        assert!(!t.insert(&1, "hello 3"));
        assert!(t.len() == 2);
    }
    #[test]
    fn test_balance() {
        let mut t = AVLTreeMap::new();
        println!("start: height={} tree={:?}", t.height(), t);
        assert!(t.height() == 0);
        assert!(t.insert(&1, "hello"));
        println!("add 1: height={} tree={:?}", t.height(), t);
        assert!(t.height() == 1);
        assert!(t.insert(&2, "hello"));
        println!("add 2: height={} tree={:?}", t.height(), t);
        assert!(t.height() == 2);
        assert!(t.insert(&3, "hello"));
        println!("add 3: height={} tree={:?}", t.height(), t);
        assert!(t.height() == 2);
        assert!(t.insert(&4, "hello"));
        println!("add 4: height={} tree={:?}", t.height(), t);
        assert!(t.height() == 3);
        assert!(t.insert(&5, "hello"));
        println!("add 5: height={} tree={:?}", t.height(), t);
        assert!(t.height() == 3);
        assert!(t.insert(&6, "hello"));
        println!("add 6: height={} tree={:?}", t.height(), t);
        assert!(t.height() == 3);
        assert!(t.insert(&7, "hello"));
        println!("add 7: height={} tree={:?}", t.height(), t);
        assert!(t.height() == 3);
        assert!(t.insert(&8, "hello"));
        println!("add 8: height={} tree={:?}", t.height(), t);
        assert!(t.height() == 4);
    }
}
