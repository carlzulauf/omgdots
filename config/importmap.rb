# Pin npm packages by running ./bin/importmap

pin "application"
pin "@rails/actioncable", to: "actioncable.esm.js"
pin "cable"
pin "play_game"
pin_all_from "app/javascript/play", under: "play"
