namespace AppManager.Utils {
    /** Animates stable app identities across rebuilds of a grid or list. */
    public class AnimatedAppView : Gtk.Widget {
        public Gtk.Widget items { get; private set; }

        private class Position : Object {
            public float x;
            public float y;

            public Position(float x, float y) {
                this.x = x;
                this.y = y;
            }
        }

        private Gee.HashMap<string, Position> previous_positions = new Gee.HashMap<string, Position>();
        private Gee.HashMap<string, Position> offsets = new Gee.HashMap<string, Position>();
        private Adw.TimedAnimation animation;
        private double progress = 1;
        private bool reorder_pending = false;

        public AnimatedAppView(Gtk.Widget items) {
            this.items = items;
            items.set_parent(this);
            weak AnimatedAppView view = this;
            var target = new Adw.CallbackAnimationTarget((value) => {
                view.progress = value;
                view.queue_allocate();
            });
            animation = new Adw.TimedAnimation(this, 0, 1, 500, target);
            animation.easing = Adw.Easing.EASE_OUT_CUBIC;
            animation.done.connect(() => {
                view.offsets.clear();
                view.queue_allocate();
            });
        }

        /** Call before replacing children; identities must survive app updates. */
        public void begin_reorder(bool enabled) {
            if (!enabled) {
                animation.reset();
                previous_positions.clear();
                offsets.clear();
                reorder_pending = false;
                queue_allocate();
                return;
            }
            // Several refreshes can arrive before the next allocation. Keep the
            // last visible positions rather than sampling unallocated new cells.
            if (reorder_pending) {
                return;
            }

            previous_positions.clear();
            if (get_mapped() && Adw.get_enable_animations(this)) {
                for (var child = items.get_first_child(); child != null; child = child.get_next_sibling()) {
                    var id = child.get_data<string>("app-id");
                    var bounds = Graphene.Rect();
                    if (id == null || !child.compute_bounds(items, out bounds)) {
                        continue;
                    }
                    previous_positions.set(id, new Position(bounds.origin.x, bounds.origin.y));
                }
            }

            animation.reset();
            offsets.clear();
            reorder_pending = !previous_positions.is_empty;
        }

        public override Gtk.SizeRequestMode get_request_mode() {
            return items.get_request_mode();
        }

        public override void measure(Gtk.Orientation orientation, int for_size,
                                     out int minimum, out int natural,
                                     out int minimum_baseline, out int natural_baseline) {
            items.measure(orientation, for_size, out minimum, out natural,
                out minimum_baseline, out natural_baseline);
        }

        public override void size_allocate(int width, int height, int baseline) {
            // Restore the container's natural allocations before applying this
            // frame's transforms. Moving allocations also keeps pointer picking
            // and focus outlines aligned with the animated cells.
            items.queue_allocate();
            items.allocate(width, height, baseline, null);

            if (!Adw.get_enable_animations(this)) {
                animation.skip();
                previous_positions.clear();
                offsets.clear();
                reorder_pending = false;
                return;
            }

            bool start_animation = reorder_pending;
            reorder_pending = false;
            for (var child = items.get_first_child(); child != null; child = child.get_next_sibling()) {
                var id = child.get_data<string>("app-id");
                var bounds = Graphene.Rect();
                if (id == null || !child.compute_bounds(items, out bounds)) {
                    continue;
                }
                if (start_animation) {
                    var previous = previous_positions.get(id);
                    if (previous != null) {
                        float dx = previous.x - bounds.origin.x;
                        float dy = previous.y - bounds.origin.y;
                        if (dx.abs() > 0.5f || dy.abs() > 0.5f) {
                            offsets.set(id, new Position(dx, dy));
                        }
                    }
                }
                var offset = offsets.get(id);
                if (offset != null) {
                    float remaining = start_animation ? 1 : (float) (1 - progress);
                    var transform = new Gsk.Transform().translate(Graphene.Point() {
                        x = bounds.origin.x + offset.x * remaining,
                        y = bounds.origin.y + offset.y * remaining
                    });
                    child.allocate((int) bounds.size.width, (int) bounds.size.height, -1, transform);
                }
            }
            previous_positions.clear();
            if (start_animation && !offsets.is_empty) {
                animation.play();
            }
        }

        public override void snapshot(Gtk.Snapshot snapshot) {
            snapshot_child(items, snapshot);
        }

        public override void unmap() {
            animation.skip();
            previous_positions.clear();
            offsets.clear();
            reorder_pending = false;
            base.unmap();
        }

        protected override void dispose() {
            if (items != null && items.get_parent() == this) {
                items.unparent();
            }
            base.dispose();
        }
    }
}
