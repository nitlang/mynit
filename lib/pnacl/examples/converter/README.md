Steps to make the example work :

1. Install the native client SDK (https://developer.chrome.com/native-client/sdk/download).

2. Declare the environment variable NACL_SDK_ROOT as the root of the target platform within the SDK (ex: ~/nacl_sdk/pepper_34/) :
	$ export NACL_SDK_ROOT=/path/to/nacl_sdk/pepper_[your_version]

3. Compile the Nit code with: `nitc --semi-global converter.nit` or `make`.

You must use the '--semi-global' (or `--global`) option. Some features in the standard library are not supported by the NaCL platform, the global compiler do not try to compile them.

4. Start a local server using: `make serve`.

5. Set up the Chrome browser :
 - PNaCl is enabled by default in Chrome version 31 and later.
 - For a better development experience, it’s also recommended to disable the Chrome cache :
	- Open Chrome’s developer tools by clicking the menu icon menu-icon and choosing Tools > Developer tools.
	- Click the gear icon gear-icon in the bottom right corner of the Chrome window.
	- Under the “General” settings, check the box next to “Disable cache (while DevTools is open)”.
	- Keep the Developer Tools pane open while developing Native Client applications.

6. You can now access the application in Chrome at the address `http://localhost:5103/`.
