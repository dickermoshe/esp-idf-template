// Detect Windows before placeholders so conditionals can skip prompts that
// do not apply (e.g. ESP-IDF install location).
let os_arch = variable::get("os-arch");
variable::set("windows", os_arch.starts_with("windows-"));
