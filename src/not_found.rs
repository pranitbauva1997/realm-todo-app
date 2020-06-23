#[realm_page(id = "Pages.NotFound")]
pub struct NotFound {
    message: String,
}

pub fn not_found(message: &str) -> NotFound {
    NotFound {
        message: message.into(),
    }
}
