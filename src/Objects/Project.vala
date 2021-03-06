/*-
 * Copyright (c) 2018-2018 Artem Anufrij <artem.anufrij@live.de>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * The Noise authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Noise. This permission is above and beyond the permissions granted
 * by the GPL license by which Noise is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Artem Anufrij <artem.anufrij@live.de>
 */

namespace TrimDown.Objects {
    public class Project : BaseObject {
        public signal void chapter_created (Objects.Chapter chapter);

        public string kind { get; private set; }

        public string chapters_path { get; private set; }

        GLib.List<Chapter> ? _chapters = null;
        public GLib.List<Chapter> chapters {
            get {
                if (_chapters == null) {
                    _chapters = get_chapter_collection ();
                }
                return _chapters;
            }
        }

        public Project (string path, string kind = "") {
            this.path = path;
            this.kind = kind;
            this.title = Path.get_basename (path);

            chapters_path = Path.build_filename (path, _ ("Chapters"));
            properties_path = Path.build_filename (path, title + ".td");

            init ();
        }

        private void init () {
            if (!FileUtils.test (properties_path, FileTest.EXISTS)) {
                try {
                    FileUtils.set_contents (properties_path, Utils.get_new_project_property (title, kind));
                } catch (Error err) {
                    warning (err.message);
                    return;
                }
            }

            load_properties ();

            kind = get_string_property ("Metadata", "kind");
        }

        private GLib.List<Chapter> get_chapter_collection () {
            GLib.List<Chapter> return_value = new GLib.List<Chapter> ();
            var directory = File.new_for_path (chapters_path);
            try {
                var children = directory.enumerate_children ("standard::*," + FileAttribute.STANDARD_CONTENT_TYPE, GLib.FileQueryInfoFlags.NONE);
                FileInfo file_info = null;

                while ((file_info = children.next_file ()) != null) {
                    if (file_info.get_file_type () == FileType.DIRECTORY) {
                        var chapter = new Chapter (this, file_info.get_name ());
                        return_value.append (chapter);
                    }
                }
            } catch (Error err) {
                warning (err.message);
            }

            return return_value;
        }

        public Chapter create_new_chapter (string name, int order) {
            var new_chapter = new Chapter (this, name, order);
            new_chapter.create_new_scene (_ ("Scene %d").printf (1), 0);
            new_chapter.create_new_note (_ ("Notes"));
            return new_chapter;
        }

        public Chapter generate_new_chapter () {
            int i = 1;
            string new_chapter_name = "";
            do {
                new_chapter_name = _ ("Chapter %d").printf (i);
                i++;
            } while (FileUtils.test (Path.build_filename (chapters_path, new_chapter_name), FileTest.EXISTS));

            var new_chapter = create_new_chapter (new_chapter_name, i);
            chapter_created (new_chapter);
            return new_chapter;
        }

        public void reorder_chapters (int from, int to) {
            var from_path = "";
            foreach (var chapter in chapters) {
                if (chapter.order == from) {
                    from_path = chapter.path;
                    if (from > to) {
                        chapter.set_new_order (to);
                    } else {
                        chapter.set_new_order (to - 1);
                    }
                }
            }

            if (from > to) {
                foreach (var chapter in chapters) {
                    if (chapter.order >= to && chapter.order < from && chapter.path != from_path) {
                        chapter.set_new_order (chapter.order + 1);
                    }
                }
            } else {
                foreach (var chapter in chapters) {
                    if (chapter.order < to && chapter.order >= from && chapter.path != from_path) {
                        chapter.set_new_order (chapter.order - 1);
                    }
                }
            }
        }
    }
}