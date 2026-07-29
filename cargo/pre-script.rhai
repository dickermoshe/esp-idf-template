let targets = #{
    esp32: #{
        arch: "xtensa",
        rust_target: "xtensa-esp32-espidf",
        gcc_target: "xtensa-esp32-elf",
        wokwi_board: "board-esp32-devkit-c-v4",
    },
    esp32c2: #{
        arch: "riscv",
        rust_target: "riscv32imc-esp-espidf",
        gcc_target: "riscv32-esp-elf",
        wokwi_board: "",
    },
    esp32c3: #{
        arch: "riscv",
        rust_target: "riscv32imc-esp-espidf",
        gcc_target: "riscv32-esp-elf",
        wokwi_board: "board-esp32-c3-devkitm-1",
    },
    esp32c5: #{
        arch: "riscv",
        rust_target: "riscv32imac-esp-espidf",
        gcc_target: "riscv32-esp-elf",
        wokwi_board: "board-esp32-c5-devkitc-1",
    },
    esp32c6: #{
        arch: "riscv",
        rust_target: "riscv32imac-esp-espidf",
        gcc_target: "riscv32-esp-elf",
        wokwi_board: "board-esp32-c6-devkitc-1",
    },
    esp32c61: #{
        arch: "riscv",
        rust_target: "riscv32imac-esp-espidf",
        gcc_target: "riscv32-esp-elf",
    },
    esp32h2: #{
        arch: "riscv",
        rust_target: "riscv32imac-esp-espidf",
        gcc_target: "riscv32-esp-elf",
        wokwi_board: "board-esp32-h2-devkitm-1",
    },
    esp32p4: #{
        arch: "riscv",
        rust_target: "riscv32imafc-esp-espidf",
        gcc_target: "riscv32-esp-elf",
        wokwi_board: "board-esp32-p4-preview",
    },
    esp32s2: #{
        arch: "xtensa",
        rust_target: "xtensa-esp32s2-espidf",
        gcc_target: "xtensa-esp32s2-elf",
        wokwi_board: "board-esp32-s2-devkitm-1",
    },
    esp32s3: #{
        arch: "xtensa",
        rust_target: "xtensa-esp32s3-espidf",
        gcc_target: "xtensa-esp32s3-elf",
        wokwi_board: "board-esp32-s3-devkitc-1",
    },
};

// Return a stable five-character base-36 fingerprint. Five characters are the
// largest identifier that keeps `C:\e\<id>` within esp-idf-sys's ten-character
// Windows build-root limit.
fn compact_build_id(value) {
    let alphabet = "0123456789abcdefghijklmnopqrstuvwxyz";
    let modulus = 60_466_176; // 36^5
    let hash = 2_166_136_261 % modulus;

    for character in value.to_lower() {
        let character_value = alphabet.index_of(character);
        if character_value < 0 {
            character_value = 36;
        }

        hash = (hash * 131 + character_value + 1) % modulus;
    }

    let id = "";
    for position in 0..5 {
        let digit = hash % 36;
        id = alphabet.sub_string(digit, 1) + id;
        hash = hash / 36;
    }

    id
}

let target = variable::get("mcu");
let target_properties = targets.get(target);
for key in target_properties.keys() {
    variable::set(key, target_properties.get(key));
}

// ESP-IDF's build tree can exceed the path length supported by some of its
// Windows tools. Cargo 1.91+ lets us relocate only intermediate artifacts,
// while keeping final artifacts in the project's regular target directory.
let os_arch = variable::get("os-arch");
let windows = os_arch.starts_with("windows-");
variable::set("windows", windows);
if windows {
    let project_identity =
        `${env::destination_directory}|${variable::get("project-name")}`;
    variable::set("short_build_id", compact_build_id(project_identity));
}

let advanced = variable::get("advanced");
if !advanced {
    variable::set("espidfver", "v5.5.3");
    variable::set("git", "false");
    variable::set("installdir", "workspace");
    variable::set("devcontainer", false);
    variable::set("wokwi", false);
}

// On Windows, ESP-IDF repeats its installation path throughout the final
// linker response file. A workspace installation beneath a long project path
// can push ldproxy past Windows' 32,767-character process-command limit.
// Preserve an explicit advanced "global" choice, but give the default
// workspace-scoped installation a short, shared physical path.
let tools_install_dir = variable::get("installdir");
if windows && tools_install_dir == "workspace" {
    tools_install_dir = "custom:C:/e/idf";
}
variable::set("tools_install_dir", tools_install_dir);
