module Kemal
  # The right way to handle context is Kemal::Handler
  # but I can not check response content type easily
  # In future release the code below could change
  class WatcherHandler
    def call(context)
      if context.response.headers["Content-Type"]? == "text/html" && context.request.headers["X-Requested-With"]? != "XMLHttpRequest"
        context.response.print <<-HTML
        <script type="text/javascript">
        var kemal_watcher_reloading = false;

        async function wait_fot_alive() {
          try {
            var response = await fetch("/");
            if (response.ok) {
              window.location.reload();
            }
          } catch {
            setTimeout(() => { wait_fot_alive() }, 1000);
          }
        }

        if ('WebSocket' in window) {
          (() => {
            var protocol = window.location.protocol === 'http:' ? 'ws://' : 'wss://';
            var address = protocol + window.location.host + '/' + `#{WEBSOCKETPATH}`;
            var ws = new WebSocket(address);
            ws.onopen = () => {
              console.log("Kemal-watcher - connected");
            };
            ws.onmessage = (msg) => {
              if (msg.data == "reload") {
                console.log("Kemal-watcher - reloading...");
                kemal_watcher_reloading = true;
                window.location.reload();
              }
            };
            ws.onclose = () => {
              if (!kemal_watcher_reloading) {
                console.log("Kemal-watcher - reconnecting...");
                setTimeout(() => {
                  wait_fot_alive();
                  //window.location.reload();
                }, 2000);
              }
            };
          })();
        }
        </script>
        HTML
      end
    end
  end

  # Handle change when event.on_change and
  # send reload message to all clients
  private def self.handle_change
    SOCKETS.each do |socket|
      socket.send "reload"
    end
  end
end
