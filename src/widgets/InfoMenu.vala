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

class InfoMenu : Gtk.MenuButton {
    private InfoPopover info_popover;
    private Gtk.Entry name_entry;

    public string name {
        get {
            return name_entry.text;
        }

        set {
            name_entry.text = value;
            name_entry.width_chars = value.length + 6;
        }
    }

    private Gtk.Label author_entry_label;

    public string author {
        get {
            return author_entry_label.label;
        }

        set {
            author_entry_label.label = value;
        }
    }

    public signal void apply ();

    construct {
        info_popover = new InfoPopover (this);
        popover =  (Gtk.Popover)info_popover; /* Property of Gtk.MenuButton */

        var grid = new Gtk.Grid ();
        grid.row_spacing = 12;
        grid.column_spacing = 6;
        grid.border_width = 12;
        popover.add (grid);

        var name_label = new InfoLabel ("Name");
        name_label.xalign = 1;
        name_entry = new Gtk.Entry ();
        name_entry.text = "";
        grid.attach (name_label, 0, 0, 1, 1);
        grid.attach (name_entry, 1, 0, 1, 1);

        var author_label = new InfoLabel ("Author");
        author_label.xalign = 1;
        author_entry_label = new Gtk.Label (""); /* Author not editable? */
        author_entry_label.xalign = 0;
        grid.attach (author_label, 0, 1, 1, 1);
        grid.attach (author_entry_label, 1, 1, 1, 1);

        clicked.connect (() => {
            store_values ();
            popover.show_all ();
        });

        info_popover.apply_settings.connect (() => {
            store_values ();
            apply ();
        });

        info_popover.cancel.connect (() => {
            restore_values ();
        });
    }

    public InfoMenu () {
        image = new Gtk.Image.from_icon_name ("help-info-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
        tooltip_text = _("Information about Current Game");
    }

    private void store_values () {
    }

    private void restore_values () {
    }

    /** Popover that can be cancelled with Escape and closed by Enter **/
    private class InfoPopover : Gtk.Popover {
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

        public InfoPopover (Gtk.Widget widget) {
            Object (relative_to: widget);
        }
    }

    private class InfoLabel : Gtk.Label {
        public InfoLabel (string? text) {
            string txt = text != null ? text + ":" : "";
            txt.replace ("::", ":");
            string markup = Markup.printf_escaped ("<span weight=\"bold\">%s</span>", txt);
            set_markup (markup);
        }
    }
}
}
