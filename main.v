module main

import time
import ui


#flag windows -luser32
#include <windows.h>

fn C.mouse_event(dwFlags int, dx int, dy int, dwData int, dwExtraInfo int)
fn C.GetAsyncKeyState(vKey int) i16

const mouse_left_down   = 0x0002
const mouse_left_up     = 0x0004
const mouse_right_down  = 0x0008
const mouse_right_up    = 0x0010
const mouse_middle_down = 0x0020
const mouse_middle_up   = 0x0040

struct App {
mut:
	is_clicking  bool
	delay        int
	button_type  string
	hotkey_code  int
}

fn get_key_code(name string) int {
	return match name {
		'f1' { 0x70 } 'f2' { 0x71 } 'f3' { 0x72 } 'f4' { 0x73 }
		'f5' { 0x74 } 'f6' { 0x75 } 'f7' { 0x76 } 'f8' { 0x77 }
		'f9' { 0x78 } 'f10' { 0x79 } 'f11' { 0x7A } 'f12' { 0x7B }
		'home' { 0x24 } 'insert' { 0x2D } 'escape' { 0x1B }
		else { 0x75 }
	}
}


fn clicker_worker(mut app App) {
	mut was_pressed := false
	mut last_click_time := time.now()

	for {

		key_state := C.GetAsyncKeyState(app.hotkey_code)
		is_down := (key_state & 0x8000) != 0

		if is_down && !was_pressed {
			app.is_clicking = !app.is_clicking

			status := if app.is_clicking { 'ВКЛ' } else { 'ВЫКЛ' }
			println('Состояние кликера: $status')
		}
		was_pressed = is_down


		if app.is_clicking {

			if time.since(last_click_time).milliseconds() >= app.delay {
				mut down := mouse_left_down
				mut up := mouse_left_up

				match app.button_type {
					'Средняя' { down = mouse_middle_down; up = mouse_middle_up }
					'Правая' { down = mouse_right_down; up = mouse_right_up }
					else { down = mouse_left_down; up = mouse_left_up }
				}

				C.mouse_event(down, 0, 0, 0, 0)
				time.sleep(2 * time.millisecond)
				C.mouse_event(up, 0, 0, 0, 0)

				last_click_time = time.now()
			}
		}


		time.sleep(10 * time.millisecond)
	}
}

fn about_program(btn &ui.Button) {
    message := 'SovelyAC версия 1.0.2\n\nСамый нормальный автокликер в мире\nНаписан через боль и страдания\n\nСделано brleol inc.'
	ui.message_box(message)
}

fn whats_new(btn &ui.Button) {
    message := 'Что нового\n1.0.2\n\nДобавлен этот диалог\nВсё\n\nА так исправлены ошибки:\nИконка\nВыключение'
    ui.message_box(message)
}

fn main() {
	mut app := &App{
		is_clicking: false
		delay: 100
		button_type: 'Левая'
		hotkey_code: 0x75 // F6
	}

	spawn clicker_worker(mut app)


	default_delay := '100'

	window := ui.window(
		width: 400
		height: 380
		title: 'SovelyAC'
		children: [
			ui.column(
				margin: ui.Margin{20, 20, 20, 20}
				spacing: 15
				children: [
					ui.label(text: 'Sovely Autoclicker', text_size: 28),
					ui.column(
						spacing: 5
						children: [
							ui.label(text: 'Кнопка мыши:'),
							ui.dropdown(
								selected_index: 0
								items: [ui.DropdownItem{text: 'Левая'}, ui.DropdownItem{text: 'Средняя'}, ui.DropdownItem{text: 'Правая'}]
								on_selection_changed: fn [mut app] (d &ui.Dropdown) {
									app.button_type = d.items[d.selected_index].text
								}
							),
						]
					),
					ui.column(
						spacing: 5
						children: [
							ui.label(text: 'Задержка (мс):'),
							ui.textbox(
								id: 'delay_box'
								text: &default_delay
								on_change: fn [mut app] (t &ui.TextBox) {
									val := t.text.int()
									if val > 0 { app.delay = val }
								}
							),
						]
					),
					ui.column(
						spacing: 5
						children: [
							ui.label(text: 'Горячая клавиша:'),
							ui.dropdown(
								items: [
									ui.DropdownItem{text: 'f1'}, ui.DropdownItem{text: 'f6'},
									ui.DropdownItem{text: 'f10'}, ui.DropdownItem{text: 'home'},
									ui.DropdownItem{text: 'escape'}
								]
								selected_index: 1
								on_selection_changed: fn [mut app] (d &ui.Dropdown) {
									app.hotkey_code = get_key_code(d.items[d.selected_index].text)
								}
							),
						]
					),
					ui.row(
						spacing: 10
						children: [
							ui.button(
								text: 'Запустить'
								on_click: fn [mut app] (btn &ui.Button) {
									app.is_clicking = true
								}
							),
							ui.button(
								text: 'Остановить'
								on_click: fn [mut app] (btn &ui.Button) {
									app.is_clicking = false
								}
							),
							ui.button(
								text: 'Инфо'
								on_click: about_program
							),
							ui.button(
								text: 'Что нового'
								on_click: whats_new
							),
						]
					),
				]
			),
		]
	)

	ui.run(window)
}
