use crate::db::{add_todo_db, get_all_todos};
pub use realm::base::*;
pub use realm::{Or404, Page as RealmPage};

#[derive(Serialize, Deserialize)]
pub struct Item {
    pub title: String,
    pub done: bool,
}

#[realm_page(id = "Pages.Index")]
struct Page {
    list: Vec<Item>,
}

pub fn empty_todo() -> realm::Result {
    let items = vec![];
    Page { list: items }.with_title("Empty Todo List")
}

pub fn clear(in_: &In0) -> realm::Result {
    // /api/todo/clear/
    let items = vec![
        Item {
            title: "hello one".to_string(),
            done: false,
        },
        Item {
            title: "hello two".to_string(),
            done: false,
        },
        Item {
            title: "hello three".to_string(),
            done: false,
        },
    ];
    std::fs::write("todos.json", &serde_json::to_vec(&items)?)?;
    redirect(in_)
}

pub fn add_todo(in_: &In0, title: String, done: bool) -> realm::Result {
    add_todo_db(in_, title, done as i32)?;
    redirect(in_)
}

pub fn todo(in_: &In0) -> realm::Result {
    // TODO: read the json file, deserialize it into vec of Item
    Page {
        list: get_all_todos(in_)?,
    }
    .with_title("ToDo List")
}

pub fn toggle(in_: &In0, index: usize) -> realm::Result {
    let mut items: Vec<Item> = serde_json::from_slice(&std::fs::read("todos.json")?)?;
    if let Some(mut item) = items.get_mut(index) {
        item.done = !item.done
    }
    std::fs::write("todos.json", &serde_json::to_vec(&items)?)?;
    redirect(in_)
}

pub fn redirect(in_: &In0) -> realm::Result {
    todo(in_).map(|r| r.with_url(crate::reverse::index()))
}
