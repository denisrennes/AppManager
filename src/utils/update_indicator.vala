namespace AppManager.Utils {
    public enum UpdatePhase {
        WAITING,
        CHECKING,
        DOWNLOADING,
        INSTALLING,
        DONE
    }

    /**
     * Per-app update progress, drawn by an animated Gtk.Svg (GTK 4.22).
     * States in update-progress.svg: waiting, checking, downloading,
     * p1..p20 (rim filled in 5% steps), installing, done.
     */
    public class UpdateIndicator : Adw.Bin {
        private const string RESOURCE = "/com/github/AppManager/update-progress.svg";
        private const uint STATE_DOWNLOADING = 2;
        private const uint PROGRESS_STEPS = 20;
        private const uint STATE_INSTALLING = 23;
        private const uint STATE_DONE = 24;

        private Gtk.Image image;
        private Gtk.Svg? svg = null;
        private uint state = 0;

        public UpdatePhase phase { get; private set; default = UpdatePhase.WAITING; }

        public int pixel_size {
            get { return image.pixel_size; }
            set { image.pixel_size = value; }
        }

        public UpdateIndicator() {
            image = new Gtk.Image();
            image.add_css_class("update-indicator");
            child = image;
            realize.connect(start_playing);
            show_phase(UpdatePhase.WAITING);
        }

        public void show_phase(UpdatePhase phase, int64 received = 0, int64 total = 0) {
            this.phase = phase;
            string description;
            switch (phase) {
                case UpdatePhase.CHECKING:
                    state = 1;
                    description = _("Checking...");
                    break;
                case UpdatePhase.DOWNLOADING:
                    state = STATE_DOWNLOADING;
                    if (total > 0) {
                        state += (uint) (int64.min(received, total) * PROGRESS_STEPS / total);
                        description = _("Downloading %s of %s").printf(UiUtils.format_size(received), UiUtils.format_size(total));
                    } else {
                        description = _("Downloading");
                    }
                    break;
                case UpdatePhase.INSTALLING:
                    state = STATE_INSTALLING;
                    description = _("Installing...");
                    break;
                case UpdatePhase.DONE:
                    state = STATE_DONE;
                    description = _("Updated");
                    break;
                default:
                    state = 0;
                    description = _("Waiting...");
                    break;
            }
            tooltip_text = description;
            update_property(Gtk.AccessibleProperty.LABEL, description, -1);
            if (svg != null) {
                svg.state = state;
            }
        }

        // A state set before playback is lost when the SVG timeline starts,
        // so the paintable is created on first realize in the current state.
        private void start_playing() {
            if (svg == null) {
                try {
                    var bytes = GLib.resources_lookup_data(RESOURCE, GLib.ResourceLookupFlags.NONE);
                    // Resource data is always NUL-terminated.
                    var text = ((string) bytes.get_data()).replace("gpa:state='0'", "gpa:state='%u'".printf(state));
                    svg = new Gtk.Svg.from_bytes(new Bytes(text.data));
                } catch (Error e) {
                    warning("Failed to load update indicator: %s", e.message);
                    return;
                }
                image.paintable = svg;
            }
            svg.set_frame_clock(get_frame_clock());
            svg.play();
        }
    }
}
