use crate::db::{add_todo_db, delete_todo, get_all_todos, toggle_todo};
pub use realm::base::*;
pub use realm::{Or404, Page as RealmPage};

#[derive(Serialize, Deserialize)]
pub struct Item {
    pub index: i32,
    pub title: String,
    pub done: bool,
}

#[realm_page(id = "Pages.Index")]
struct Page {
    list: Vec<Item>,
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

pub fn toggle(in_: &In0, index: i32) -> realm::Result {
    toggle_todo(in_, index)?;
    redirect(in_)
}

pub fn redirect(in_: &In0) -> realm::Result {
    todo(in_).map(|r| r.with_url(crate::reverse::index()))
}

pub fn delete(in_: &In0, index: i32) -> realm::Result {
    delete_todo(in_, index)?;
    redirect(in_)
}
