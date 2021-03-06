/* Displays clues for gnonograms-elementary
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

class AppMenu : Gtk.MenuButton {
    private const Difficulty MIN_GRADE = Difficulty.EASY; /* TRIVIAL and VERY EASY GRADES not worth supporting */
    private AppPopover app_popover;
    private AppSetting grade_setting;
    private AppSetting row_setting;
    private AppSetting column_setting;
    private Gtk.Grid grid;

    private uint _grade_val;
    public uint grade_val {
        get {
            return _grade_val;
        }

        set {
            _grade_val = value;
            grade_setting.set_value (value);
        }
    }

    private uint _row_val;
    public uint row_val {
        get {
            return _row_val;
        }

        set {
            _row_val = value;
            row_setting.set_value (value);
        }
    }

    private uint _column_val;
    public uint column_val {
        get {
            return _column_val;
        }

        set {
            _column_val = value;
            column_setting.set_value (value);
        }
    }

    public signal void apply ();

    construct {
        popover = new AppPopover (this);
        app_popover = (AppPopover)popover;

        grid = new Gtk.Grid ();
        popover.add (grid);

        grade_setting = new GradeChooser ();
        row_setting = new ScaleGrid (_("Rows"), 10, 50, 5);
        column_setting = new ScaleGrid (_("Columns"), 10, 50, 5);

        int pos = 0;
        add_setting (ref pos, grade_setting);
        add_setting (ref pos, row_setting);
        add_setting (ref pos, column_setting);

        grid.margin = 12;
        grid.row_spacing = 6;
        grid.column_spacing = 6;

        clicked.connect (() => {
            store_values ();
            popover.show_all ();
        });

        app_popover.apply_settings.connect (() => {
            store_values ();
            apply ();
        });

        app_popover.cancel.connect (() => {
            restore_values ();
        });
    }

    public AppMenu () {
        image = new Gtk.Image.from_icon_name ("open-menu", Gtk.IconSize.LARGE_TOOLBAR);
        tooltip_text = _("Options");
    }

    private void store_values () {
        grade_val = (uint)(grade_setting.get_value ());
        row_val = (uint)(row_setting.get_value ());
        column_val = (uint)(column_setting.get_value ());
    }

    private void restore_values () {
        grade_setting.set_value (grade_val);
        row_setting.set_value (row_val);
        column_setting.set_value (column_val);
    }

    private void add_setting (ref int pos, AppSetting setting) {
        var label = setting.get_heading ();
        label.xalign = 1;
        grid.attach (label, 0, pos, 1, 1);
        grid.attach (setting.get_chooser (), 1, pos, 1, 1);
        pos++;
    }

    /** Popover that can be cancelled with Escape and closed by Enter **/
    private class AppPopover : Gtk.Popover {
        private bool cancelled = false;
        public signal void apply_settings ();
        public signal void cancel ();


        construct {
            closed.connect (() => {
                if (!cancelled) {
                    apply_settings ();
                } else {
                    cancel ();
                }

                cancelled = false;
            });

            key_press_event.connect ((event) => {
                cancelled = (event.keyval == Gdk.Key.Escape);

                if (event.keyval == Gdk.Key.KP_Enter || event.keyval == Gdk.Key.Return) {
                    hide ();
                }
            });
        }

        public AppPopover (Gtk.Widget widget) {
            Object (relative_to: widget);
        }
    }

    /** Setting Widget using a Scale limited to integral values separated by step (interface uses uint) **/
    protected class ScaleGrid :Object, AppSetting {
        public string heading {get; set;}
        public Gtk.Grid chooser {get; set;}
        public Gtk.Label heading_label {get; set;}
        public Gtk.Label val_label {get; set;}
        public AppScale scale {get; set;}

        construct {
            val_label = new Gtk.Label ("");
            chooser = new Gtk.Grid ();
            chooser.column_spacing = 6;
        }

        public ScaleGrid (string _heading, uint _start, uint _end, uint _step) {
            Object (heading: _heading);
            scale = new AppScale (_start, _end, _step);
            scale.expand = false;

            ((Gtk.Widget)scale).valign = Gtk.Align.START;

            scale.value_changed.connect (() => {
                var val = (uint)(scale.get_value ());
                val_label.label = val.to_string ();
                value_changed (val);
            });

            heading_label = new Gtk.Label (heading);
            val_label.xalign = 0;

            chooser.attach (scale, 0, 0, 1, 1);
            chooser.attach (val_label, 1, 0, 1, 1);
        }

        public void set_value (uint val) {
            scale.set_value (val);
            val_label.label = scale.get_value ().to_string ();
        }

        public uint get_value () {
            return scale.get_value ();
        }

        public Gtk.Label get_heading () {
            return heading_label;
        }

        public Gtk.Widget get_chooser () {
            return chooser;
        }

        protected class AppScale : Gtk.Scale {
            private uint step;

            public AppScale (uint _start, uint _end, uint _step) {
                var start = (double)_start / (double)_step;
                var end = (double)_end / (double)_step + 1.0;
                step = _step;
                var _adjustment = new Gtk.Adjustment (start, start, end, 1.0, 1.0, 1.0);
                this.adjustment = _adjustment;

                for (var val = start; val <= end; val += 1.0) {
                    add_mark (val, Gtk.PositionType.BOTTOM, null);
                }

                hexpand = true;
                draw_value = false;

                set_size_request ((int)(end - start) * 20, -1);
            }

            public new uint get_value () {
                return (uint)(base.get_value () + 0.3) * step;
            }

            public new void set_value (uint val) {
                base.set_value ((double)val / (double)step);
                value_changed ();
            }
        }
    }

    protected class GradeChooser : Object, AppSetting {
        Gtk.ComboBoxText cb;
        Gtk.Label heading;

        construct {
            cb = new Gtk.ComboBoxText ();

            foreach (Difficulty d in Difficulty.all_human ()) {
                cb.append (((uint)d).to_string (), d.to_string ());
            }

            cb.changed.connect (() => {
                value_changed ((uint)(cb.active));
            });

            cb.expand = false;
            heading = new Gtk.Label (_("Generated games"));
        }

        public void set_value (uint grade) {
            cb.active_id = grade.clamp (MIN_GRADE, Difficulty.MAXIMUM).to_string ();
        }

        public uint get_value () {
            return (uint)(int.parse (cb.active_id));
        }

        public Gtk.Label get_heading () {
            return heading;
        }

        public Gtk.Widget get_chooser () {
            return cb;
        }

    }
}

public interface AppSetting : Object {
    public signal void value_changed (uint val);
    public abstract void set_value (uint val);
    public abstract uint get_value ();
    public abstract Gtk.Label get_heading ();
    public abstract Gtk.Widget get_chooser ();
}
}
