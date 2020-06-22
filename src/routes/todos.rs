use crate::prelude::*;

#[derive(Serialize, Deserialize)]
struct Item {
    title: String,
    done: bool,
}

#[realm_page(id = "Pages.ToDo")]
struct Page {
    list: Vec<Item>,
}

pub fn clear() -> realm::Result {
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
    redirect()
}

pub fn todo() -> realm::Result {
    // TODO: read the json file, deserialize it into vec of Item
    Page {
        list: serde_json::from_slice(&std::fs::read("todos.json")?)?,
    }
    .with_title("ToDo List")
}

pub fn toggle(index: usize) -> realm::Result {
    let mut items: Vec<Item> = serde_json::from_slice(&std::fs::read("todos.json")?)?;
    if let Some(mut item) = items.get_mut(index) {
        item.done = !item.done
    }
    std::fs::write("todos.json", &serde_json::to_vec(&items)?)?;
    redirect()
}

pub fn redirect() -> realm::Result {
    todo().map(|r| r.with_url(crate::reverse::todo()))
}
