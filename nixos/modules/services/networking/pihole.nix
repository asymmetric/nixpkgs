{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.pi-hole;
  dnsmasqConfig = pkgs.writeText "dnsmasq.conf" ''
    addn-hosts=/var/lib/pihole/gravity.list
    addn-hosts=/var/lib/pihole/black.list
    addn-hosts=/var/lib/pihole/local.list

    domain-needed

    localise-queries

    bogus-priv

    no-resolv

    ${strings.concatMapStringsSep "\n" (x: "server=${x}") cfg.nameservers}

    interface=${cfg.interface}

    cache-size=10000

    ${optionalString (cfg.logQueries) "log-queries"}
    log-facility=/var/log/pihole/pihole.log

    local-ttl=2

    log-async

    # If a DHCP client claims that its name is "wpad", ignore that.
    # This fixes a security hole. see CERT Vulnerability VU#598349
    dhcp-name-match=set:wpad-ignore,wpad
    dhcp-ignore-names=tag:wpad-ignore
  '';
  setupVars = pkgs.writeText "setupVars.conf" ''
    IPV4_ADDRESS=${cfg.address.ipv4}
    ${optionalString (cfg.address.ipv6 != null) "IPV6_ADDRESS=${cfg.address.ipv6}"}
    PIHOLE_INTERFACE=${cfg.interface}
    ${strings.concatImapStringsSep "\n" (pos: x: "PIHOLE_DNS_${toString pos}=${x}") cfg.nameservers}
    BLOCKING_ENABLED=true
    QUERY_LOGGING=${toString cfg.logQueries}
  '';
  ftlConf =
    let
      yesNo = yes: if yes then "yes" else "no";
    in
      pkgs.writeText "pihole-FTL.conf" ''
        LOGFILE=${cfg.ftl.logFile}
        PIDFILE=${cfg.ftl.pidFile}
        PORTFILE=${cfg.ftl.portFile}
        SOCKETFILE=${cfg.ftl.socketFile}
        SOCKET_LISTENING=${cfg.ftl.socketListening}
        QUERY_DISPLAY=${yesNo cfg.ftl.queryDisplay}
        AAAA_QUERY_ANALYSIS=${yesNo cfg.ftl.aaaaQueryAnalysis}
        ANALYZE_ONLY_A_AND_AAAA=${yesNo cfg.ftl.analyzeOnlyAAndAAAA}
        RESOLVE_IPV4=${yesNo cfg.ftl.resolveIPv4}
        RESOLVE_IPV6=${yesNo cfg.ftl.resolveIPv6}
        MAXDBDAYS=${toString cfg.ftl.maxDBDays}
        DBINTERVAL=${toString cfg.ftl.dbInterval}
        DBFILE=${cfg.ftl.dbFile}
        MAXLOGAGE=${toString cfg.ftl.maxLogAge}
        FTLPORT=${toString cfg.ftl.port}
        PRIVACYLEVEL=${toString cfg.ftl.privacyLevel}
        IGNORE_LOCALHOST=${yesNo cfg.ftl.ignoreLocalhost}
        BLOCKINGMODE=${cfg.ftl.blockingMode}
      '';
  blocklists = pkgs.writeText "adlists.list" cfg.blocklists;

in
{
  ###### interface
  options = {
    services.pi-hole = {
      enable = mkEnableOption "Pi-hole service";

      interface = mkOption {
        description = "The networking interface.";
        type = types.str;
        example = "eth0";
      };

      address = {
        ipv4 = mkOption {
          type = types.str;
          description = "The IPv4 address of the interface";
          example = "192.168.130.10";
        };

        ipv6 = mkOption {
          description = "The IPv6 address of the interface";
          type = with types; nullOr str;
          example = "2001:16b8:5cd7:1200:6257:18ff:fad1:d490";
          default = null;
        };
      };

      nameservers = mkOption {
        description = "Upstream DNS servers";
        type = types.listOf types.str;
        example = [
          # Google (ECS)
          "8.8.8.8"
          "8.8.4.4"
          "2001:4860:4860:0:0:0:0:8888"
          "2001:4860:4860:0:0:0:0:8844"
          # OpenDNS (ECS)
          "208.67.222.222"
          "208.67.220.220"
          "2620:0:ccc::2"
          "2620:0:ccd::2"
          # Level3
          "Level3"
          "4.2.2.1"
          "4.2.2.2"
          # Comodo
          "8.26.56.26"
          "8.20.247.20"
          # DNS.WATCH
          "84.200.69.80"
          "84.200.70.40"
          "2001:1608:10:25:0:0:1c04:b12f"
          "2001:1608:10:25:0:0:9249:d69b"
          # Quad9 (filtered, DNSSEC)
          "9.9.9.9"
          "149.112.112.112"
          "2620:fe::fe"
          "2620:fe::9"
          # Quad9 (unfiltered, no DNSSEC)
          "9.9.9.10"
          "149.112.112.10"
          "2620:fe::10"
          "2620:fe::fe:10"
          # Quad9 (filtered + ECS)
          "9.9.9.11"
          "149.112.112.11"
          "2620:fe::11"
          # Cloudflare
          "1.1.1.1"
          "1.0.0.1"
          "2606:4700:4700::1111"
          "2606:4700:4700::1001"
        ];
      };

      openFirewall = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to open ports in the firewall.

          The webserver port will only be opened if <literal>services.pihole.webUI.enable</literal> is <literal>true</literal>.
        '';
      };

      webUI = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Whether to enable the web UI, served by nginx.

            Further nginx configuration can be declared by adapting <literal>services.nginx.virtualHosts.&lt;name&gt;</literal>.

            See <xref linkend="opt-services.nginx.virtualHosts"/> for further information.
          '';
        };

        port = mkOption {
          type = types.port;
          default = 80;
          example = 443;
          description = "The port the web server should listen on.";
        };

        hostName = mkOption {
          description = "Hostname for the vhost.";
          type = types.str;
          default = "localhost";
        };

      };

      blocklists = mkOption {
        description = "Blocklists to use";
        type = types.str;
        default = ''
          https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
          https://mirror1.malwaredomains.com/files/justdomains
          http://sysctl.org/cameleon/hosts
          https://zeustracker.abuse.ch/blocklist.php?download=domainblocklist
          https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt
          https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt
          https://hosts-file.net/ad_servers.txt
        '';
      };

      user = mkOption {
        description = "User to run Pi-hole as";
        type = types.str;
        default = "pihole";
        example = "pihole";
      };

      group = mkOption {
        description = "Group to run Pi-hole under";
        type = types.str;
        default = "pihole";
        example = "pihole";
      };

      location = mkOption {
        description = "URL at which Pi-hole is reachable";
        type = types.str;
        default = "/";
      };

      logLife = mkOption {
        description = "How long to keep logs around for";
        type = types.str;
        default = "90d";
      };

      ftl = {
        logFile = mkOption {
          description = "Path to the log file";
          type = types.path;
          default = "/var/log/pihole/ftl.log";
          example = "/var/log/pihole/ftl.log";
        };

        pidFile = mkOption {
          description = "Path to the file containing the daemon's PID";
          type = types.path;
          default = "/run/pihole/ftl.pid";
          example = "/run/pihole/ftl.pid";
        };

        portFile = mkOption {
          description = "Path to the file containing the port the daemon is listening on";
          type = types.path;
          default = "/run/pihole/ftl.port";
          example = "/run/pihole/ftl.port";
        };

        socketFile = mkOption {
          description = "Path to the daemon's socket";
          type = types.path;
          default = "/run/pihole/ftl.socket";
          example = "/run/pihole/ftl.socket";
        };

        socketListening = mkOption {
          description = ''
            Whether the FTL daemon should listening for local socket connections only, or all connections.
            Valid values are: <literal>localonly</literal>, <literal>all</literal>.
          '';
          type = types.str;
          default = "localonly";
          example = "all";
        };

        queryDisplay = mkOption {
          description = "Whether to display all queries.";
          type = types.bool;
          default = true;
        };

        aaaaQueryAnalysis = mkOption {
          description = "Whether to allow FTL to analyze AAAA queries from pihole.log";
          type = types.bool;
          default = true;
        };

        analyzeOnlyAAndAAAA = mkOption {
          description = "Whether FTL should only analyze A and AAAA queries.";
          type = types.bool;
          default = false;
        };

        resolveIPv4 = mkOption {
          description = "Whether FTL should try to resolve IPv4 addresses to host names.";
          type = types.bool;
          default = true;
        };

        resolveIPv6 = mkOption {
          description = "Whether FTL should try to resolve IPv6 addresses to host names.";
          type = types.bool;
          default = true;
        };

        maxDBDays = mkOption {
          description = "How long to keep queries stored in the database, in days.";
          type = types.int;
          default = 365;
          example = 365;
        };

        dbInterval = mkOption {
          description = "How often to store queries in the database, in minutes.";
          type = types.float;
          default = 1.0;
          example = 1.0;
        };

        dbFile = mkOption {
          description = "Path to the daemon's database file";
          type = types.path;
          default = "/var/lib/pihole/pihole-FTL.db";
          example = "/var/lib/pihole/pihole-FTL.db";
        };

        maxLogAge = mkOption {
          description = "How many hours of queries to import from the database and logs";
          type = types.float;
          default = 24.0;
          example = 24.0;
        };

        port = mkOption {
          description = "The port FTL should listen on.";
          type = types.port;
          default = 4711;
          example = 4711;
        };

        privacyLevel = mkOption {
          description = ''
            The privacy level, as documented at https://docs.pi-hole.net/ftldns/privacylevels/.

            Valid values are: 0, 1, 2, 3.
          '';
          type = types.int;
          default = 0;
          example = 3;
        };

        ignoreLocalhost = mkOption {
          description = "Whether to ignore queries coming from localhost";
          type = types.bool;
          default = false;
        };

        blockingMode = mkOption {
          description = ''
            How FTL should reply to blocked queries.

            Valid values are: <literal>NULL</literal>, <literal>IP-NODATA-AAA</literal>, <literal>IP</literal>, <literal>NXDOMAIN</literal>.
          '';
          type = types.str;
          default = "NULL";
          example = "NXDOMAIN";
        };
      };

      logQueries = mkOption {
        description = "Whether queries should be logged";
        type = types.bool;
        default = true;
      };

      interval = mkOption {
        type = types.str;
        default = "daily";
        example = "Mon *-*-* 00:00:00";
        description = ''
          Update the adblock lists at this interval.

          The format is described in
          <citerefentry><refentrytitle>systemd.time</refentrytitle>
          <manvolnum>7</manvolnum></citerefentry>.
        '';
      };
    };
  };

  ###### implementation
  config = mkIf cfg.enable {

    systemd.services.pi-hole-ftl = {
      description = "Pi-hole FTLDNS engine";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
        ExecStartPre = ''
          ${pkgs.pi-hole-ftl}/bin/pihole-FTL dnsmasq-test
        '';
        ExecStart = "${pkgs.pi-hole-ftl}/bin/pihole-FTL no-daemon -- --conf-file=${dnsmasqConfig}";
        ExecReload = "${pkgs.utillinux}/bin/kill -HUP $MAINPID";
        Restart = "on-failure";
        AmbientCapabilities= [ "CAP_NET_BIND_SERVICE" ];
        RuntimeDirectory = [ "pihole" ];
        LogsDirectory = [ "pihole" ];
        StateDirectory = [ "pihole" ];
      };
    };

    systemd.tmpfiles.rules = [
      "L+ /etc/pihole/dnsmasq.conf - - - - ${dnsmasqConfig}"
      "L+ /etc/pihole/setupVars.conf - - - - ${setupVars}"
      "L+ /etc/pihole/pihole-FTL.conf - - - - ${ftlConf}"
      "L+ /var/lib/pihole/adlists.list - - - - ${blocklists}"
    ];

    systemd.services.pi-hole-updater = {
      description = "Pi-hole";
      wants = [ "network.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
        ExecStart = "${pkgs.pi-hole}/bin/pihole -g";
        LogsDirectory = [ "pihole" ];
        StateDirectory = [ "pihole" ];
      };

      startAt = cfg.interval;
    };

    services.nginx = {
      enable = cfg.webUI.enable;
      user = cfg.user;
      group = cfg.group;
      recommendedOptimisation = true;
      recommendedTlsSettings = true;
      recommendedGzipSettings = true;
      recommendedProxySettings = true;
      virtualHosts."${cfg.webUI.hostName}" = {
        root = "${pkgs.pi-hole}/var/www";

        locations = {
          "= /" = {
            extraConfig = ''
              rewrite / /pihole/index.php;
            '';
          };
          "/admin" = {
            root = "${pkgs.pi-hole-admin}/var/www";
            index = "index.php";
            tryFiles = "$uri $uri/ /index.php";
          };
          "~ /admin.*\\.php$" = {
            root = "${pkgs.pi-hole-admin}/var/www";
            extraConfig = ''
              fastcgi_pass unix:/run/phpfpm/pi-hole.sock;
            '';
          };
          "~ \\.php$" = {
            extraConfig = ''
              fastcgi_pass unix:/run/phpfpm/pi-hole.sock;
            '';
          };
        };
      };
    };

    users = {
      users."${cfg.user}" = {
        isSystemUser = true;
        group = cfg.group;
      };
      groups."${cfg.group}" = {};
    };

    security.polkit.extraConfig = ''
      // Allow user pihole to manage system service pi-hole-ftl.service
      polkit.addRule(function(action, subject) {
          if (action.id == "org.freedesktop.systemd1.manage-units" &&
              action.lookup("unit") == "pi-hole-ftl.service" &&
              subject.user == "${cfg.user}") {
                return polkit.Result.YES;
          }
      });
    '';

    services.phpfpm = lib.mkIf cfg.webUI.enable {
      pools.pi-hole = {
        listen = "/run/phpfpm/pi-hole.sock";
        extraConfig = ''
          listen.owner = ${cfg.user}
          listen.group = ${cfg.group}
          user = ${cfg.user}
          group = ${cfg.group}
          pm = dynamic
          pm.max_children = 10
          pm.start_servers = 2
          pm.min_spare_servers = 2
          pm.max_spare_servers = 4
          pm.max_requests = 500
        '';
      };
    };

    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [ 53 ] ++ optional cfg.webUI.enable cfg.webUI.port;
    };
  };
}
