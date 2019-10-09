import qbs
import qbs.TextFile
import qbs.Environment

Module {
	additionalProductTypes: ["cutehmi.dirs.hpp"]

	setupRunEnvironment: {
		if (product.qbs.targetOS.contains("windows"))
			Environment.putEnv("PATH", product.cutehmi.dirs.externalLibDir + product.qbs.pathListSeparator + Environment.getEnv("PATH"))
		else
			Environment.putEnv("LD_LIBRARY_PATH", product.cutehmi.dirs.externalLibDir + product.qbs.pathListSeparator + Environment.getEnv("LD_LIBRARY_PATH"))

		Environment.putEnv("QML2_IMPORT_PATH", product.cutehmi.dirs.installDir + "/" + product.cutehmi.dirs.extensionInstallDirname)

		Environment.putEnv("CUTEHMI_INSTALL_DIR", product.cutehmi.dirs.installDir)
	}

	property bool generateHeaderFile: false

	property string installDir: product.qbs.installPrefix ? product.qbs.installRoot + product.qbs.installPrefix : product.qbs.installRoot // Note: qbs.installPrefix starts with "/".

	property string examplesInstallDirname: "examples"

	// <qbs-cutehmi-dirs-1.workaround target="Qt" cause="design">
	// Android expects QML files to be installed in 'qml' directory, so we're changing installation path of extension files.
	property string extensionInstallDirname: qbs.targetOS.contains("android") ? "qml" : "bin"
	// </qbs-cutehmi-dirs-1.workaround>

	property string extensionsSourceDir: project.sourceDirectory + "/extensions"

	property string externalDeployDir: project.sourceDirectory + "/external/deploy"

	property string externalLibDir: externalDeployDir + "/lib"

	property string externalIncludeDir: externalDeployDir + "/include"

	property string testInstallDirname: "bin"

	property string toolInstallDirname: "bin"

	FileTagger {
		patterns: ["*.qbs"]
		fileTags: ["qbs"]
	}

	Rule {
		condition: product.cutehmi.dirs.generateHeaderFile
		inputs: ["qbs"]

		prepare: {
			var hppCmd = new JavaScriptCommand();
			hppCmd.description = "generating " + product.sourceDirectory + "/cutehmi.dirs.hpp"
			hppCmd.highlight = "codegen";
			hppCmd.sourceCode = function() {
				var f = new TextFile(product.sourceDirectory + "/cutehmi.dirs.hpp", TextFile.WriteOnly);
				try {
					var prefix = "CUTEHMI_DIRS"

					f.writeLine("#ifndef " + prefix + "_HPP")
					f.writeLine("#define " + prefix + "_HPP")

					f.writeLine("")
					f.writeLine("// This file has been autogenerated by Qbs cutehmi.dirs module.")
					f.writeLine("")

					f.writeLine("#define " + prefix + "_TOOL_INSTALL_DIRNAME \"" + product.cutehmi.dirs.toolInstallDirname + "\"")
					f.writeLine("#define " + prefix + "_TEST_INSTALL_DIRNAME \"" + product.cutehmi.dirs.testInstallDirname + "\"")
					f.writeLine("#define " + prefix + "_EXTENSION_INSTALL_DIRNAME \"" + product.cutehmi.dirs.extensionInstallDirname + "\"")
					f.writeLine("")
					f.writeLine("#endif")
				} finally {
					f.close()
				}
			}

			return [hppCmd]
		}

		Artifact {
			filePath: product.sourceDirectory + "/cutehmi.dirs.hpp"
			fileTags: ["cutehmi.dirs.hpp", "hpp"]
		}
	}
}

//(c)MP: Copyright © 2019, Michal Policht <michpolicht@gmail.com>. All rights reserved.
//(c)MP: This file is a part of CuteHMI.
//(c)MP: CuteHMI is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
//(c)MP: CuteHMI is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more details.
//(c)MP: You should have received a copy of the GNU Lesser General Public License along with CuteHMI.  If not, see <https://www.gnu.org/licenses/>.
