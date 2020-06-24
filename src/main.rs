use realm::base::*;
realm::realm! {middleware}

pub fn http404(msg: &str) -> realm::Result {
    use realm::Page;
    realm_tutorial::not_found::not_found(msg).with_title(msg)
}

pub fn middleware(ctx: &realm::Context) -> realm::Result {
    observer::create_context("middleware");

    let conn = sqlite::connection()?;
    let in_: In0 = realm::base::In::from(&conn, ctx);

    realm::end_context(&in_, route(&in_), |_, m| http404(m))
}

pub fn route(in_: &In0) -> realm::Result {
    let mut input = in_.ctx.input()?;

    match in_.ctx.pm() {
        t if realm::is_realm_url(t) => realm::handle(in_, t, &mut input),
        ("/", _) => realm_tutorial::routes::index::todo(in_),
        ("/add-todo/", _) => realm_tutorial::routes::index::add_todo(
            in_,
            input.required("title")?,
            input.required("done")?,
        ),
        ("/empty_todos/", _) => realm_tutorial::routes::index::empty_todo(),
        ("/api/clear-todo/", _) => realm_tutorial::routes::index::clear(in_),
        ("/api/toggle-todo/", _) => {
            realm_tutorial::routes::index::toggle(in_, input.required("index")?)
        }
        _ => realm_tutorial::routes::index::todo(in_),
    }
}
