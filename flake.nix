{
  description = "A Nix-based continuous build system";

  inputs.nixpkgs.follows = "nix/nixpkgs";

  outputs = { self, nixpkgs, nix }:
    let

      version = "${builtins.readFile ./version}.${builtins.substring 0 8 self.lastModifiedDate}.${self.shortRev or "DIRTY"}";

      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [ self.overlay nix.overlay ];
      };

      # NixOS configuration used for VM tests.
      hydraServer =
        { config, pkgs, ... }:
        { imports = [ self.nixosModules.hydraTest ];

          virtualisation.memorySize = 1024;
          virtualisation.writableStore = true;

          environment.systemPackages = [ pkgs.perlPackages.LWP pkgs.perlPackages.JSON ];

          nix = {
            # Without this nix tries to fetch packages from the default
            # cache.nixos.org which is not reachable from this sandboxed NixOS test.
            binaryCaches = [];
          };
        };

    in rec {

      # A Nixpkgs overlay that provides a 'hydra' package.
      overlay = final: prev: {

        # Add LDAP dependencies that aren't currently found within nixpkgs.
        perlPackages = prev.perlPackages // {
          TestPostgreSQL = final.perlPackages.buildPerlModule {
            pname = "Test-PostgreSQL";
            version = "1.27";
            src = final.fetchurl {
              url = "mirror://cpan/authors/id/T/TJ/TJC/Test-PostgreSQL-1.27.tar.gz";
              sha256 = "b1bd231693100cc40905fb0ba3173173201621de9c8301f21c5b593b0a46f907";
            };
            buildInputs = with final.perlPackages; [ ModuleBuildTiny TestSharedFork pkgs.postgresql ];
            propagatedBuildInputs = with final.perlPackages; [ DBDPg DBI FileWhich FunctionParameters Moo TieHashMethod TryTiny TypeTiny ];

            makeMakerFlags = "POSTGRES_HOME=${final.postgresql}";

            meta = {
              homepage = https://github.com/TJC/Test-postgresql;
              description = "PostgreSQL runner for tests";
              license = with final.lib.licenses; [ artistic2 ];
            };
          };

          FunctionParameters = final.buildPerlPackage {
            pname = "Function-Parameters";
            version = "2.001003";
            src = final.fetchurl {
              url = "mirror://cpan/authors/id/M/MA/MAUKE/Function-Parameters-2.001003.tar.gz";
              sha256 = "eaa22c6b43c02499ec7db0758c2dd218a3b2ab47a714b2bdf8010b5ee113c242";
            };
            buildInputs = with final.perlPackages; [ DirSelf TestFatal ];
            meta = {
              description = "Define functions and methods with parameter lists (\"subroutine signatures\")";
              license = with final.lib.licenses; [ artistic1 gpl1Plus ];
            };
          };

          DirSelf = final.buildPerlPackage {
            pname = "Dir-Self";
            version = "0.11";
            src = final.fetchurl {
              url = "mirror://cpan/authors/id/M/MA/MAUKE/Dir-Self-0.11.tar.gz";
              sha256 = "e251a51abc7d9ba3e708f73c2aa208e09d47a0c528d6254710fa78cc8d6885b5";
            };
            meta = {
              homepage = "https://github.com/mauke/Dir-Self";
              description = "A __DIR__ constant for the directory your source file is in";
              license = with final.lib.licenses; [ artistic1 gpl1Plus ];
            };
          };

          TieHashMethod = final.buildPerlPackage {
              pname = "Tie-Hash-Method";
              version = "0.02";
              src = final.fetchurl {
                url = "mirror://cpan/authors/id/Y/YV/YVES/Tie-Hash-Method-0.02.tar.gz";
                sha256 = "d513fbb51413f7ca1e64a1bdce6194df7ec6076dea55066d67b950191eec32a9";
              };
              meta = {
                description = "Tied hash with specific methods overriden by callbacks";
                license = with final.lib.licenses; [ artistic1 ];
              };
            };

          Test2Harness = final.buildPerlPackage {
            pname = "Test2-Harness";
            version = "1.000042";
            src = final.fetchurl {
              url = "mirror://cpan/authors/id/E/EX/EXODIST/Test2-Harness-1.000042.tar.gz";
              sha256 = "aaf231a68af1a6ffd6a11188875fcf572e373e43c8285945227b9d687b43db2d";
            };

            checkPhase = ''
              patchShebangs ./t ./scripts/yath
              ./scripts/yath test -j $NIX_BUILD_CORES
            '';

            propagatedBuildInputs = with final.perlPackages; [ DataUUID Importer LongJump ScopeGuard TermTable Test2PluginMemUsage Test2PluginUUID Test2Suite gotofile ];
            meta = {
              description = "A new and improved test harness with better Test2 integration";
              license = with final.lib.licenses; [ artistic1 gpl1Plus ];
            };
          };

          Test2PluginMemUsage = prev.perlPackages.buildPerlPackage {
            pname = "Test2-Plugin-MemUsage";
            version = "0.002003";
            src = final.fetchurl {
              url = "mirror://cpan/authors/id/E/EX/EXODIST/Test2-Plugin-MemUsage-0.002003.tar.gz";
              sha256 = "5e0662d5a823ae081641f5ce82843111eec1831cd31f883a6c6de54afdf87c25";
            };
            buildInputs = with final.perlPackages; [ Test2Suite ];
            meta = {
              description = "Collect and display memory usage information";
              license = with final.lib.licenses; [ artistic1 gpl1Plus ];
            };
          };

          Test2PluginUUID = prev.perlPackages.buildPerlPackage {
            pname = "Test2-Plugin-UUID";
            version = "0.002001";
            src = final.fetchurl {
              url = "mirror://cpan/authors/id/E/EX/EXODIST/Test2-Plugin-UUID-0.002001.tar.gz";
              sha256 = "4c6c8d484d7153d8779dc155a992b203095b5c5aa1cfb1ee8bcedcd0601878c9";
            };
            buildInputs = with final.perlPackages;[ Test2Suite ];
            propagatedBuildInputs = with final.perlPackages; [ DataUUID ];
            meta = {
              description = "Use REAL UUIDs in Test2";
              license = with final.lib.licenses; [ artistic1 gpl1Plus ];
            };
          };

          LongJump = final.buildPerlPackage {
            pname = "Long-Jump";
            version = "0.000001";
            src = final.fetchurl {
              url = "mirror://cpan/authors/id/E/EX/EXODIST/Long-Jump-0.000001.tar.gz";
              sha256 = "d5d6456d86992b559d8f66fc90960f919292cd3803c13403faac575762c77af4";
            };
            buildInputs = with final.perlPackages; [ Test2Suite ];
            meta = {
              description = "Mechanism for returning to a specific point from a deeply nested stack";
              license = with final.lib.licenses; [ artistic1 gpl1Plus ];
            };
          };

          gotofile = final.buildPerlPackage {
            pname = "goto-file";
            version = "0.005";
            src = final.fetchurl {
              url = "mirror://cpan/authors/id/E/EX/EXODIST/goto-file-0.005.tar.gz";
              sha256 = "c6cdd5ee4a6cdcbdbf314d92a4f9985dbcdf9e4258048cae76125c052aa31f77";
            };
            buildInputs = with final.perlPackages; [ Test2Suite ];
            meta = {
              description = "Stop parsing the current file and move on to a different one";
              license = with final.lib.licenses; [ artistic1 gpl1Plus ];
            };
          };

          NetLDAPServer = prev.perlPackages.buildPerlPackage {
            pname = "Net-LDAP-Server";
            version = "0.43";
            src = final.fetchurl {
              url = "mirror://cpan/authors/id/A/AA/AAR/Net-LDAP-Server-0.43.tar.gz";
              sha256 = "0qmh3cri3fpccmwz6bhwp78yskrb3qmalzvqn0a23hqbsfs4qv6x";
            };
            propagatedBuildInputs = with final.perlPackages; [ NetLDAP ConvertASN1 ];
            meta = {
              description = "LDAP server side protocol handling";
              license = with final.stdenv.lib.licenses; [ artistic1 ];
            };
          };

          NetLDAPSID = prev.perlPackages.buildPerlPackage {
            pname = "Net-LDAP-SID";
            version = "0.0001";
            src = final.fetchurl {
              url = "mirror://cpan/authors/id/K/KA/KARMAN/Net-LDAP-SID-0.001.tar.gz";
              sha256 = "1mnnpkmj8kpb7qw50sm8h4sd8py37ssy2xi5hhxzr5whcx0cvhm8";
            };
            meta = {
              description= "Active Directory Security Identifier manipulation";
              license = with final.stdenv.lib.licenses; [ artistic2 ];
            };
          };

          NetLDAPServerTest = prev.perlPackages.buildPerlPackage {
            pname = "Net-LDAP-Server-Test";
            version = "0.22";
            src = final.fetchurl {
              url = "mirror://cpan/authors/id/K/KA/KARMAN/Net-LDAP-Server-Test-0.22.tar.gz";
              sha256 = "13idip7jky92v4adw60jn2gcc3zf339gsdqlnc9nnvqzbxxp285i";
            };
            propagatedBuildInputs = with final.perlPackages; [ NetLDAP NetLDAPServer TestMore DataDump NetLDAPSID ];
            meta = {
              description= "test Net::LDAP code";
              license = with final.stdenv.lib.licenses; [ artistic1 ];
            };
          };

          CatalystAuthenticationStoreLDAP = prev.perlPackages.buildPerlPackage {
            pname = "Catalyst-Authentication-Store-LDAP";
            version = "1.016";
            src = final.fetchurl {
              url = "mirror://cpan/authors/id/I/IL/ILMARI/Catalyst-Authentication-Store-LDAP-1.016.tar.gz";
              sha256 = "0cm399vxqqf05cjgs1j5v3sk4qc6nmws5nfhf52qvpbwc4m82mq8";
            };
            propagatedBuildInputs = with final.perlPackages; [ NetLDAP CatalystPluginAuthentication ClassAccessorFast ];
            buildInputs = with final.perlPackages; [ TestMore TestMockObject TestException NetLDAPServerTest ];
            meta = {
              description= "Authentication from an LDAP Directory";
              license = with final.stdenv.lib.licenses; [ artistic1 ];
            };
          };
        };

        hydra = with final; let
          perlDeps = buildEnv {
            name = "hydra-perl-deps";
            paths = with perlPackages; lib.closePropagation
              [ ModulePluggable
                CatalystActionREST
                CatalystAuthenticationStoreDBIxClass
                CatalystAuthenticationStoreLDAP
                CatalystDevel
                CatalystDispatchTypeRegex
                CatalystPluginAccessLog
                CatalystPluginAuthorizationRoles
                CatalystPluginCaptcha
                CatalystPluginSessionStateCookie
                CatalystPluginSessionStoreFastMmap
                CatalystPluginStackTrace
                CatalystPluginUnicodeEncoding
                CatalystTraitForRequestProxyBase
                CatalystViewDownload
                CatalystViewJSON
                CatalystViewTT
                CatalystXScriptServerStarman
                CatalystXRoleApplicator
                CryptRandPasswd
                DBDPg
                DBDSQLite
                DataDump
                DateTime
                DigestSHA1
                EmailMIME
                EmailSender
                FileSlurp
                FileWhich
                IOCompress
                IPCRun
                JSON
                JSONAny
                JSONXS
                LinuxInotify2
                LWP
                LWPProtocolHttps
                NetAmazonS3
                NetPrometheus
                NetStatsd
                PadWalker
                Readonly
                SQLSplitStatement
                SetScalar
                Starman
                SysHostnameLong
                TermSizeAny
                TestMore
                TestPostgreSQL
                TextDiff
                Test2Harness
                TextTable
                XMLSimple
                YAML
                final.nix.perl-bindings
                git
              ];
          };

        in stdenv.mkDerivation {

          name = "hydra-${version}";

          src = self;

          buildInputs =
            [ makeWrapper autoconf automake libtool unzip nukeReferences pkgconfig libpqxx
              gitAndTools.topGit mercurial darcs subversion breezy openssl bzip2 libxslt
              final.nix perlDeps perl mdbook
              boost
              postgresql_11
              (if lib.versionAtLeast lib.version "20.03pre"
               then nlohmann_json
               else nlohmann_json.override { multipleHeaders = true; })
            ];

          checkInputs = [
            foreman
          ];

          hydraPath = lib.makeBinPath (
            [ subversion openssh final.nix coreutils findutils pixz
              gzip bzip2 lzma gnutar unzip git gitAndTools.topGit mercurial darcs gnused breezy
            ] ++ lib.optionals stdenv.isLinux [ rpm dpkg cdrkit ] );

          shellHook = ''
            pushd $(git rev-parse --show-toplevel) >/dev/null

            PATH=$(pwd)/src/hydra-evaluator:$(pwd)/src/script:$(pwd)/src/hydra-eval-jobs:$(pwd)/src/hydra-queue-runner:$PATH
            PERL5LIB=$(pwd)/src/lib:$PERL5LIB
            export HYDRA_HOME="$(pwd)/src/"
            mkdir -p .hydra-data
            export HYDRA_DATA="$(pwd)/.hydra-data"
            export HYDRA_DBI='dbi:Pg:dbname=hydra;host=localhost;port=64444'

            popd >/dev/null
          '';

          preConfigure = "autoreconf -vfi";

          NIX_LDFLAGS = [ "-lpthread" ];

          enableParallelBuilding = true;

          doCheck = true;

          preCheck = ''
            patchShebangs .
            export LOGNAME=''${LOGNAME:-foo}
            # set $HOME for bzr so it can create its trace file
            export HOME=$(mktemp -d)
          '';

          postInstall = ''
            mkdir -p $out/nix-support

            for i in $out/bin/*; do
                read -n 4 chars < $i
                if [[ $chars =~ ELF ]]; then continue; fi
                wrapProgram $i \
                    --prefix PERL5LIB ':' $out/libexec/hydra/lib:$PERL5LIB \
                    --prefix PATH ':' $out/bin:$hydraPath \
                    --set HYDRA_RELEASE ${version} \
                    --set HYDRA_HOME $out/libexec/hydra \
                    --set NIX_RELEASE ${final.nix.name or "unknown"}
            done
          '';

          dontStrip = true;

          meta.description = "Build of Hydra on ${system}";
          passthru = { inherit perlDeps; inherit (final) nix; };
        };
      };

      hydraJobs = {

        build.x86_64-linux = packages.x86_64-linux.hydra;

        manual =
          pkgs.runCommand "hydra-manual-${version}" {}
          ''
            mkdir -p $out/share
            cp -prvd ${pkgs.hydra}/share/doc $out/share/

            mkdir $out/nix-support
            echo "doc manual $out/share/doc/hydra" >> $out/nix-support/hydra-build-products
          '';

        tests.install.x86_64-linux =
          with import (nixpkgs + "/nixos/lib/testing-python.nix") { system = "x86_64-linux"; };
          simpleTest {
            machine = hydraServer;
            testScript =
              ''
                machine.wait_for_job("hydra-init")
                machine.wait_for_job("hydra-server")
                machine.wait_for_job("hydra-evaluator")
                machine.wait_for_job("hydra-queue-runner")
                machine.wait_for_open_port("3000")
                machine.succeed("curl --fail http://localhost:3000/")
              '';
          };

        tests.api.x86_64-linux =
          with import (nixpkgs + "/nixos/lib/testing-python.nix") { system = "x86_64-linux"; };
          simpleTest {
            machine = { pkgs, ... }: {
              imports = [ hydraServer ];
              # No caching for PathInput plugin, otherwise we get wrong values
              # (as it has a 30s window where no changes to the file are considered).
              services.hydra-dev.extraConfig = ''
                path_input_cache_validity_seconds = 0
              '';
            };
            testScript =
              let dbi = "dbi:Pg:dbname=hydra;user=root;"; in
              ''
                machine.wait_for_job("hydra-init")

                # Create an admin account and some other state.
                machine.succeed(
                    """
                        su - hydra -c "hydra-create-user root --email-address 'alice@example.org' --password foobar --role admin"
                        mkdir /run/jobset /tmp/nix
                        chmod 755 /run/jobset /tmp/nix
                        cp ${./t/api-test.nix} /run/jobset/default.nix
                        chmod 644 /run/jobset/default.nix
                        chown -R hydra /run/jobset /tmp/nix
                """
                )

                machine.succeed("systemctl stop hydra-evaluator hydra-queue-runner")
                machine.wait_for_job("hydra-server")
                machine.wait_for_open_port("3000")

                # Run the API tests.
                machine.succeed(
                    "su - hydra -c 'perl -I ${pkgs.hydra.perlDeps}/lib/perl5/site_perl ${./t/api-test.pl}' >&2"
                )
              '';
        };

        tests.notifications.x86_64-linux =
          with import (nixpkgs + "/nixos/lib/testing-python.nix") { system = "x86_64-linux"; };
          simpleTest {
            machine = { pkgs, ... }: {
              imports = [ hydraServer ];
              services.hydra-dev.extraConfig = ''
                <influxdb>
                  url = http://127.0.0.1:8086
                  db = hydra
                </influxdb>
              '';
              services.influxdb.enable = true;
            };
            testScript = ''
              machine.wait_for_job("hydra-init")

              # Create an admin account and some other state.
              machine.succeed(
                  """
                      su - hydra -c "hydra-create-user root --email-address 'alice@example.org' --password foobar --role admin"
                      mkdir /run/jobset
                      chmod 755 /run/jobset
                      cp ${./t/api-test.nix} /run/jobset/default.nix
                      chmod 644 /run/jobset/default.nix
                      chown -R hydra /run/jobset
              """
              )

              # Wait until InfluxDB can receive web requests
              machine.wait_for_job("influxdb")
              machine.wait_for_open_port("8086")

              # Create an InfluxDB database where hydra will write to
              machine.succeed(
                  "curl -XPOST 'http://127.0.0.1:8086/query' "
                  + "--data-urlencode 'q=CREATE DATABASE hydra'"
              )

              # Wait until hydra-server can receive HTTP requests
              machine.wait_for_job("hydra-server")
              machine.wait_for_open_port("3000")

              # Setup the project and jobset
              machine.succeed(
                  "su - hydra -c 'perl -I ${pkgs.hydra.perlDeps}/lib/perl5/site_perl ${./t/setup-notifications-jobset.pl}' >&2"
              )

              # Wait until hydra has build the job and
              # the InfluxDBNotification plugin uploaded its notification to InfluxDB
              machine.wait_until_succeeds(
                  "curl -s -H 'Accept: application/csv' "
                  + "-G 'http://127.0.0.1:8086/query?db=hydra' "
                  + "--data-urlencode 'q=SELECT * FROM hydra_build_status' | grep success"
              )
            '';
        };

        tests.ldap.x86_64-linux =
          with import (nixpkgs + "/nixos/lib/testing-python.nix") { system = "x86_64-linux"; };
          makeTest {
            machine = { pkgs, ... }: {
              imports = [ hydraServer ];

              services.openldap = {
                enable = true;
                suffix = "dc=example";
                rootdn = "cn=root,dc=example";
                rootpw = "notapassword";
                database = "bdb";
                dataDir = "/var/lib/openldap";
                extraConfig = ''
                  moduleload pw-sha2
                '';
                extraDatabaseConfig = ''
                '';

                # userPassword generated via `slappasswd -o module-load=pw-sha2  -h '{SSHA256}'`
                # The admin user has the password `password and `user` has the password `foobar`.
                declarativeContents = ''
                  dn: dc=example
                  dc: example
                  o: Root
                  objectClass: top
                  objectClass: dcObject
                  objectClass: organization

                  dn: ou=users,dc=example
                  ou: users
                  description: All users
                  objectClass: top
                  objectClass: organizationalUnit

                  dn: ou=groups,dc=example
                  ou: groups
                  description: All groups
                  objectClass: top
                  objectClass: organizationalUnit

                  dn: cn=hydra_admin,ou=groups,dc=example
                  cn: hydra_admin
                  description: Hydra Admin user group
                  objectClass: groupOfNames
                  member: cn=admin,ou=users,dc=example

                  dn: cn=user,ou=users,dc=example
                  objectClass: organizationalPerson
                  objectClass: inetOrgPerson
                  sn: user
                  cn: user
                  mail: user@example
                  userPassword: {SSHA256}B9rfUbNgv8nIGn1Hm5qbVQdv6AIQb012ORJwegqELB0DWCzoMCY+4A==

                  dn: cn=admin,ou=users,dc=example
                  objectClass: organizationalPerson
                  objectClass: inetOrgPerson
                  sn: admin
                  cn: admin
                  mail: admin@example
                  userPassword: {SSHA256}meKP7fSWhkzXFC1f8RWRb8V8ssmN/VQJp7xJrUFFcNUDuwP1PbitMg==
                '';
              };
              systemd.services.hdyra-server.environment.CATALYST_DEBUG = "1";
              systemd.services.hydra-server.environment.HYDRA_LDAP_CONFIG = pkgs.writeText "config.yaml"
                # example config based on https://metacpan.org/source/ILMARI/Catalyst-Authentication-Store-LDAP-1.016/README#L103
                ''
                  credential:
                    class: Password
                    password_field: password
                    password_type: self_check
                  store:
                    class: LDAP
                    ldap_server: localhost
                    ldap_server_options.timeout: 30
                    binddn: "cn=root,dc=example"
                    bindpw: notapassword
                    start_tls: 0
                    start_tls_options:
                      verify:  none
                    user_basedn: "ou=users,dc=example"
                    user_filter: "(&(objectClass=inetOrgPerson)(cn=%s))"
                    user_scope: one
                    user_field: cn
                    user_search_options:
                      deref: always
                    use_roles: 1
                    role_basedn: "ou=groups,dc=example"
                    role_filter: "(&(objectClass=groupOfNames)(member=%s))"
                    role_scope: one
                    role_field: cn
                    role_value: dn
                    role_search_options:
                      deref: always
                  '';
              networking.firewall.enable = false;
            };
            testScript = ''
              import json

              machine.wait_for_unit("openldap.service")
              machine.wait_for_job("hydra-init")
              machine.wait_for_open_port("3000")
              response = machine.succeed(
                  "curl --fail http://localhost:3000/login -H 'Accept: application/json' -H 'Referer: http://localhost:3000' --data 'username=user&password=foobar'"
              )

              response_json = json.loads(response)
              assert "user" == response_json["username"]
              assert "user@example" == response_json["emailaddress"]
              assert len(response_json["userroles"]) == 0

              # logging on with wrong credentials shouldn't work
              machine.fail(
                  "curl --fail http://localhost:3000/login -H 'Accept: application/json' -H 'Referer: http://localhost:3000' --data 'username=user&password=wrongpassword'"
              )

              # the admin user should get the admin role from his group membership in `hydra_admin`
              response = machine.succeed(
                  "curl --fail http://localhost:3000/login -H 'Accept: application/json' -H 'Referer: http://localhost:3000' --data 'username=admin&password=password'"
              )

              response_json = json.loads(response)
              assert "admin" == response_json["username"]
              assert "admin@example" == response_json["emailaddress"]
              assert "admin" in response_json["userroles"]
            '';
          };

        tests.validate-openapi = pkgs.runCommand "validate-openapi"
          { buildInputs = [ pkgs.openapi-generator-cli ]; }
          ''
            openapi-generator-cli validate -i ${./hydra-api.yaml}
            touch $out
          '';

        container = nixosConfigurations.container.config.system.build.toplevel;
      };

      checks.x86_64-linux.build = hydraJobs.build.x86_64-linux;
      checks.x86_64-linux.install = hydraJobs.tests.install.x86_64-linux;
      checks.x86_64-linux.validate-openapi = hydraJobs.tests.validate-openapi;

      packages.x86_64-linux.hydra = pkgs.hydra;
      defaultPackage.x86_64-linux = pkgs.hydra;

      nixosModules.hydra = {
        imports = [ ./hydra-module.nix ];
        nixpkgs.overlays = [ self.overlay nix.overlay ];
      };

      nixosModules.hydraTest = {
        imports = [ self.nixosModules.hydra ];

        services.hydra-dev.enable = true;
        services.hydra-dev.hydraURL = "http://hydra.example.org";
        services.hydra-dev.notificationSender = "admin@hydra.example.org";

        systemd.services.hydra-send-stats.enable = false;

        services.postgresql.enable = true;
        services.postgresql.package = pkgs.postgresql_11;

        # The following is to work around the following error from hydra-server:
        #   [error] Caught exception in engine "Cannot determine local time zone"
        time.timeZone = "UTC";

        nix.extraOptions = ''
          allowed-uris = https://github.com/
        '';
      };

      nixosModules.hydraProxy = {
        services.httpd = {
          enable = true;
          adminAddr = "hydra-admin@example.org";
          extraConfig = ''
            <Proxy *>
              Order deny,allow
              Allow from all
            </Proxy>

            ProxyRequests     Off
            ProxyPreserveHost On
            ProxyPass         /apache-errors !
            ErrorDocument 503 /apache-errors/503.html
            ProxyPass         /       http://127.0.0.1:3000/ retry=5 disablereuse=on
            ProxyPassReverse  /       http://127.0.0.1:3000/
          '';
        };
      };

      nixosConfigurations.container = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules =
          [ self.nixosModules.hydraTest
            self.nixosModules.hydraProxy
            { system.configurationRevision = self.rev;

              boot.isContainer = true;
              networking.useDHCP = false;
              networking.firewall.allowedTCPPorts = [ 80 ];
              networking.hostName = "hydra";

              services.hydra-dev.useSubstitutes = true;
            }
          ];
      };

    };
}
