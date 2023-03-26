#[warn(non_snake_case)]
use druid::widget::Label;
use druid::{AppLauncher, Widget, WindowDesc};

fn build_ui() -> impl Widget<()> {
    Label::new("Launcher Test")
}

fn main() {
    let main_window = WindowDesc::new(build_ui())
        .window_size((300.0, 200.0))
        .title("SourceLauncher");
    let initial_data = ();

    AppLauncher::with_window(main_window)
        .launch(initial_data)
        .expect("Failed to launch application");
}

