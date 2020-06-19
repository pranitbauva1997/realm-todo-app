pub use realm::base::*;
pub use realm::Page as RealmPage;

#[realm_page(id = "Pages.Index")]
struct Page {
    message: String,
    count: i32,
}

pub fn get(in_: &In0) -> realm::Result {
    Page {
        message: "hello world".to_string(),
        count: crate::db::get_count(in_)?,
    }
    .with_title("Welcome")
}

pub fn redirect(in_: &In0) -> realm::Result {
    get(in_).map(|r| r.with_url(crate::reverse::index()))
}
