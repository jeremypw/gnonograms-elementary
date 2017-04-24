/* Controller class for gnonograms-elementary
 * Copyright (C) 2010-2017  Jeremy Wootten
 *
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 *  Author:
 *  Jeremy Wootten <jeremyw@elementaryos.org>
 */
namespace Gnonograms {
public class Controller : GLib.Object {
    private View gnonogram_view;
    private Gtk.HeaderBar? header_bar;
    private Granite.Widgets.ModeButton mode_switch;
    private int setting_index;
    private int solving_index;

    private CellGrid cell_grid;
    private LabelBox row_clue_box;
    private LabelBox column_clue_box;
    private Model? model;
    private GameState _game_state;
    public GameState game_state {
        get {
            return _game_state;
        }

        private set {
            if (_game_state != value) {
                _game_state = value;

                initialize_cursor ();
                if (model != null && header_bar != null) {
                    if (value == GameState.SETTING) {
                        model.display_solution ();
                        header_bar.subtitle = _("Setting");
                    } else {
                        model.display_working ();
                        header_bar.subtitle = _("Solving");
                    }
                }
            }
        }
    }
    private Cell current_cell;
    private Cell previous_cell;

    private File? _game;
    public File? game {
        get {
            return _game;
        }

        set {
            _game = value;
            if (value != null && header_bar != null) {
                header_bar.title = value.get_uri ();
            }
        }
    }
    public Dimensions dimensions {get; set;}
    private uint rows {get { return dimensions.height; }}
    private uint cols {get { return dimensions.width; }}

    private double _fontheight;
    public double fontheight {
        set {
            _fontheight = value;
            row_clue_box.fontheight = value;
            column_clue_box.fontheight = value;
        }

        get {
            return _fontheight;
        }
    }

    public Gtk.Window window {
        get {
            return (Gtk.Window)gnonogram_view;
        }
    }

    construct {
        if (Granite.Services.Logger.DisplayLevel != Granite.Services.LogLevel.DEBUG) {
            Granite.Services.Logger.DisplayLevel = Granite.Services.LogLevel.INFO;
        }

        header_bar = new Gtk.HeaderBar ();
        header_bar.set_has_subtitle (true);
        header_bar.set_show_close_button (true);

        mode_switch = new Granite.Widgets.ModeButton ();
        var setting_icon = new Gtk.Image.from_icon_name ("edit-symbolic", Gtk.IconSize.MENU); /* provisional only */
        var solving_icon = new Gtk.Image.from_icon_name ("process-working-symbolic", Gtk.IconSize.MENU);  /* provisional only */

        setting_icon.set_data ("mode", GameState.SETTING);
        solving_icon.set_data ("mode", GameState.SOLVING);

        setting_index = mode_switch.append (setting_icon);
        solving_index = mode_switch.append (solving_icon);

        header_bar.pack_start (mode_switch);

        game_state = GameState.UNDEFINED;
    }

    public Controller (File? game = null) {
        Object (game: game);

        restore_settings ();
        create_view_and_model (dimensions);
        connect_signals ();
        initialize_view ();

        if (game == null || !load_game (game)) {
            new_game ();
        }
    }

    private void create_view_and_model (Dimensions dimensions) {
        model = new Model (dimensions);

        row_clue_box = new LabelBox (Gtk.Orientation.VERTICAL, dimensions);
        column_clue_box = new LabelBox (Gtk.Orientation.HORIZONTAL, dimensions);
        cell_grid = new CellGrid (model.display_data);

        gnonogram_view = new Gnonograms.View (row_clue_box, column_clue_box, cell_grid);
        gnonogram_view.set_titlebar (header_bar);
        gnonogram_view.show_all();
    }

    private void connect_signals () {
        cell_grid.cursor_moved.connect (on_grid_cursor_moved);
        cell_grid.leave_notify_event.connect (on_grid_leave);

        mode_switch.mode_changed.connect (on_mode_switch_changed);

        gnonogram_view.key_press_event.connect(on_view_key_press_event);
    }

    private void new_game () {
        model.fill_random (7);
        header_bar.set_title (_("Random game"));
        initialize_view ();
        update_labels_from_model ();
        set_mode_switch (GameState.SOLVING);
    }

    private void initialize_view () {
        initialize_cursor ();
        set_fontheight_from_dimensions (dimensions);
    }

    private void initialize_cursor () {
        current_cell = NULL_CELL;
        previous_cell = NULL_CELL;
    }

    private void set_fontheight_from_dimensions (Dimensions dimensions) {
        assert (row_clue_box != null && column_clue_box != null);

        double max_h, max_w;
        var scr = Gdk.Screen.get_default();

        max_h = (double)(scr.get_height()) / ((double)(dimensions.height));
        max_w = (double)(scr.get_width()) / ((double)(dimensions.width));

        fontheight = double.min (max_h, max_w) / 3.0;
    }

    private void save_game_state () {
    }

    private void restore_settings () {
        dimensions = {15, 20}; /* TODO implement saving and restoring settings */
    }

    private bool load_game (File game) {
        new_game ();  /* TODO implement saving and restoring settings */
        return true;
    }

    private void update_labels_from_model () {
        for (int r = 0; r < rows; r++) {
            row_clue_box.update_label_text (r, model.get_label_text (r, false));
        }

        for (int c = 0; c < cols; c++) {
            column_clue_box.update_label_text (c, model.get_label_text (c, true));
        }
    }

    private void highlight_labels (Cell c, bool is_highlight) {
        row_clue_box.highlight (c.row, is_highlight);
        column_clue_box.highlight (c.col, is_highlight);
    }

    private void set_mode_switch (GameState gs) {
        if (gs == GameState.SETTING) {
            mode_switch.set_active (setting_index);
        } else {
            mode_switch.set_active (solving_index);
        }
    }

/*** Signal Handlers ***/

    private void on_grid_cursor_moved (Cell cell) {
        /* Assume only called if current cell changed */
        previous_cell.copy (current_cell);
        current_cell.copy (cell); /* copy needed ?*/

        if (current_cell != NULL_CELL) {
            current_cell.state = model.get_data_for_cell (current_cell);
        }

        highlight_labels (previous_cell, false);
        highlight_labels (current_cell, true);
    }

    private bool on_grid_leave () {
        highlight_labels (current_cell, false);
        current_cell = NULL_CELL;
        return false;
    }

    private bool on_view_key_press_event (Gdk.EventKey e) {
        string name = (Gdk.keyval_name (e.keyval)).up();
        int r = 0; int c = 0;

        if (current_cell != NULL_CELL) {
            r = (int)current_cell.row;
            c = (int)current_cell.col;
        }

        switch (name) {
            case "UP":
                    r -= 1;
                    break;
            case "DOWN":
                    r += 1;
                    break;
            case "LEFT":
                    c -= 1;
                    break;
            case "RIGHT":
                    c += 1;
                    break;

            default:
                    return false;
        }

        /* Confine cursor to grid when moving with arrow keys */
        r = r.clamp (0, (int)rows - 1 );
        c = c.clamp (0, (int)cols - 1 );

        cell_grid.move_cursor_to ({(uint)r, (uint)c, CellState.UNDEFINED});

        return true;
    }

    private void on_mode_switch_changed (Gtk.Widget widget) {
        GameState data = widget.get_data ("mode");
        game_state = data;
    }

    public void quit () {
        save_game_state ();
    }
}
}
