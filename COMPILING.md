<h1 align="center">CLWO Trouble in Terrorist Town Compiling</h1>
<p align="center">
    Instruction on how to compile the clwo-ttt repository.
</p>

## Environment Setup

### SourceMod (Popey's Setup)

1. Download Visual Studio Code (https://code.visualstudio.com/)
2. Install the SourcePawn Language Server (https://marketplace.visualstudio.com/items?itemName=dreae.sourcepawn-vscode)
2. Clone the clwo-ttt repository (`git clone https://github.com/classwolves/clwo-ttt`)
3. Download Sourcemod for your system (http://www.sourcemod.net/downloads.php) as well as TTT (https://github.com/Bara/TroubleinTerroristTown)
4. Extract Sourcemod and TTT to a known directory.
5. Update the VS: Code Settings to point to the unzipped directory.
6. Add a task to build a file:

Example tasks.json
```
{
  // See https://go.microsoft.com/fwlink/?LinkId=733558
  // for the documentation about the tasks.json format
  "version": "2.0.0",
	"options": {
		"shell": {
			"executable": "cmd.exe",
			"args": [
				"/d", "/c"
			]
		}
	},
  "tasks": [
    {
      "label": "Compile plugin",
      "type": "process",
      "command": "\\path\\to\\spcomp.exe",
      "args": [
        "-i\\path\\to\\includes",
        "-i\\path\\to\\more\\includes",
        "-i\\these\\stack",
        "${file}"
      ],
      "group": {
        "kind": "build",
        "isDefault": true
      },
      "problemMatcher": []
    }
  ]
}
```
