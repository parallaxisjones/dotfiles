# Overlay to skip fish tests on darwin
# Fish 4.2.1 test failures on darwin are due to missing pexpect Python module
# The tests are run via ninja build system, so we need to prevent the test target from being built
final: prev:
  with prev.lib;
  optionalAttrs prev.stdenv.isDarwin {
    fish = prev.fish.overrideAttrs (oldAttrs: {
      # Disable the check phase
      doCheck = false;
      # Patch CMakeLists.txt more aggressively to disable tests
      postPatch = (oldAttrs.postPatch or "") + ''
        # Find and disable the test target in CMakeLists.txt
        if [ -f CMakeLists.txt ]; then
          # Strategy 1: Comment out the entire add_custom_target block for fish_run_tests
          # This uses a more robust sed pattern that handles multi-line blocks
          awk '
            /add_custom_target\(fish_run_tests/ {
              in_target = 1
              print "# " $0
              next
            }
            in_target && /^[[:space:]]*\)/ {
              print "# " $0
              in_target = 0
              next
            }
            in_target {
              print "# " $0
              next
            }
            { print }
          ' CMakeLists.txt > CMakeLists.txt.tmp && mv CMakeLists.txt.tmp CMakeLists.txt || true
          
          # Strategy 2: Also try to replace test commands as fallback
          sed -i 's|test_driver.py|echo "Tests disabled"|g' CMakeLists.txt || true
          sed -i 's|cargo test|echo "Tests disabled"|g' CMakeLists.txt || true
        fi
      '';
      # Override checkPhase
      checkPhase = "echo 'Tests disabled on darwin'";
    });
  };
