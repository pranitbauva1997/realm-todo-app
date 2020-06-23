use realm::base::*;
realm::realm! {middleware}

pub fn middleware(ctx: &realm::Context) -> realm::Result {
    let conn = sqlite::connection()?;
    let in_: In0 = realm::base::In::from(&conn, ctx);

    route(&in_)
}

pub fn route(in_: &In0) -> realm::Result {
    let mut input = in_.ctx.input()?;

    match in_.ctx.pm() {
        t if realm::is_realm_url(t) => realm::handle(in_, t, &mut input),
        ("/", _) => realm_tutorial::routes::todos::todo(),
        ("/add-todo/", _) => realm_tutorial::routes::todos::add_todo(
            in_,
            input.required("title")?,
            input.required("done")?,
        ),
        ("/empty_todos/", _) => realm_tutorial::routes::todos::empty_todo(),
        ("/api/clear-todo/", _) => realm_tutorial::routes::todos::clear(),
        ("/api/toggle-todo/", _) => realm_tutorial::routes::todos::toggle(input.required("index")?),
        ("/increment/", _) => realm_tutorial::routes::increment::get(in_),
        _ => realm_tutorial::routes::index::get(in_),
    }
}
