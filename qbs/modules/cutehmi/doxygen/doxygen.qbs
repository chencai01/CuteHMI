import qbs
import qbs.File
import qbs.FileInfo
import qbs.TextFile

/**
  This module generates 'Doxyfile' artifact, which can be used by Doxygen tool to generate documentation.
  */
Module {
	additionalProductTypes: ["Doxyfile"]

	/**
	  Whether to generate redirection file in product source directory.
	  */
	property bool generateRedirectionFile: false

	/**
	  Whether to use Doxyqml.
	  */
	property bool useDoxyqml: false

	/**
	  Whether to use input filter. If this property is set to true a _sed_ script will be used for _Doxygen_ `INPUT_FILTER`. This
	  script appends `index.html` to Markdown links which end with slash (/). This is required for offline documentation. Web
	  browser won't load index.html` without the aid of HTTP.
	  */
	property bool useInputFilter: true

	/**
	  Warn about undocumented members. This property translates to WARN_IF_UNDOCUMENTED Doxygen tag. Doxygen will generate warnings
	  for undocumented members, if this property is set to @p true.
	  */
	property bool warnIfUndocumented: true

	/**
	  Exclude files or directories. This property is translated to Doxygen EXCLUDE tag. According to Doxygen manual:
	  "the EXCLUDE tag can be used to specify files and/or directories that should be excluded from the INPUT source files".
	  */
	property var exclude: []

	/**
	  Raw Doxygen tags. This property can be used to override default Doxygen tags created by this module or provide additional
	  ones. A Javascript object with Doxygen tags as keys and their associated values should be provided. For example, following
	  assignment will override PROJECT_NAME tag (normally obtained from Qbs product description) and add two EXCLUDE_PATTERNS
	  entries.
	  @code
	  cutehmi.doxygen.tags: ({'PROJECT_NAME': 'Stuxnet', 'EXCLUDE_PATTERNS': ["*.dll", "*.stl"]})
	  @endcode
	  */
	property var tags: ({})

	FileTagger {
		patterns: ["*.qbs"]
		fileTags: ["qbs"]
	}

	Rule {
		inputs: ['qbs']

		prepare: {
			var doxCmd = new JavaScriptCommand();
			doxCmd.description = 'generating ' + product.sourceDirectory + '/cutehmi.doxygen.Doxyfile'
			doxCmd.highlight = 'codegen';
			doxCmd.sourceCode = function() {
				var docDir = project.sourceDirectory + '/doc/Doxygen/docs'
//<workaround id="qbs-cutehmi-doxygen-2" target="Doxygen" cause="missing">
				// To make relative links work properly first directory of the product location has to be stripped (e.g., 'cutehmi_1' instead of 'modules/cutehmi_1').
				var outputDir = docDir +  '/' + FileInfo.relativePath(project.sourceDirectory, product.sourceDirectory).split('/').slice(1).join('/') // Absolute.
				// Instead of:
				// var outputDir = docDir +  '/' + FileInfo.relativePath(project.sourceDirectory, product.sourceDirectory) // Absolute.
//</workaround>
				// This is used to pick proper ProductLayout file. Doxygen is troublesome when it comes to subdirectories.
				var subLevel = FileInfo.relativePath(product.sourceDirectory, project.sourceDirectory).length / 3 - 1 // Amount of "../" in relativePath - 1.
				var doxygenOptions = {
					'PROJECT_NAME': product.vendor + ' - ' + product.friendlyName + ' (' + product.name + ')',
					'PROJECT_NUMBER': product.major + '.' + product.minor + '.' + product.micro,
					'PROJECT_LOGO': 'doc/project_logo.png',
					'OUTPUT_DIRECTORY': FileInfo.relativePath(product.sourceDirectory, outputDir),
					'HTML_OUTPUT': '.',
					'HTML_DYNAMIC_MENUS': false,
					'ALWAYS_DETAILED_SEC': true,
					'JAVADOC_AUTOBRIEF': true,
					'EXTRACT_ALL': true,
					'INPUT': '.',
					'RECURSIVE': true,
					'USE_MDFILE_AS_MAINPAGE': 'README.md',
					'GENERATE_LATEX': false,
					'GENERATE_TREEVIEW': true,
					'QUIET': true,
					'GENERATE_TAGFILE': 'doxygen.tag',
					'INPUT_FILTER' : product.cutehmi.doxygen.useInputFilter ? 'sed \'s/\\(\\[[[:alnum:][:blank:]\\/.:_@#-]*\\]([[:alnum:]\\/.:_@#-]*\\/\\)\\()\\)/\\1index.html\\2/g\'' : undefined,
					'ALIASES': ['principle{1}=\\xrefitem principles \\"Principle\\" \\"Principles\\" \\b %\\1 \\n',
								'assumption{1}=\\xrefitem assumptions \\"Assumption\\" \\"Assumptions\\" \\b %\\1 \\n',
								'threadsafe=\\remark This method is thread-safe.',
								'quote{1}=<div style=\'text-align:right; margin-right: 24px\'><em>\\1</em></div>\\n'

					],
					'MACRO_EXPANSION': true,
					'EXPAND_ONLY_PREDEF': true,
					'PREDEFINED': ['DOXYGEN_WORKAROUND',
								   'Q_DECLARE_TR_FUNCTIONS()=',
								   'QT_RCC_MANGLE_NAMESPACE()=',
								   //<qbs-cutehmi-doxygen-3.workaround target="Doxygen" cause="bug">
								   'Q_DECLARE_LOGGING_CATEGORY()='
								   //</qbs-cutehmi-doxygen-3.workaround target="Doxygen" cause="bug">
					],
					'LAYOUT_FILE': FileInfo.relativePath(product.sourceDirectory, project.sourceDirectory) + 'doc/layout/ProductLayout' + subLevel + '.xml',
					'SHOW_FILES': true,
					'SHOW_USED_FILES': false,
					'WARN_IF_UNDOCUMENTED': product.cutehmi.doxygen.warnIfUndocumented,
					'WARN_NO_PARAMDOC': true,
					'FILTER_PATTERNS': product.cutehmi.doxygen.useDoxyqml ? ['*.qml=doxyqml'] : undefined,
					'FILE_PATTERNS' : product.cutehmi.doxygen.useDoxyqml ? ['*.qml'] : undefined,
					'EXTENSION_MAPPING' : product.cutehmi.doxygen.useDoxyqml ? ['qml=C++'] : undefined,
					'EXCLUDE': product.cutehmi.doxygen.exclude,
					'CASE_SENSE_NAMES': false,
					'IMAGE_PATH': 'doc'
				}
				// Merge doxygenOptions with product.cutehmi.doxygen.tags (Object.assign() is unfortunately not available in Qbs 1.12).
				for (var option in product.cutehmi.doxygen.tags)
					doxygenOptions[option] = product.cutehmi.doxygen.tags[option]

//<workaround id="qbs-cutehmi-doxygen-2" target="Doxygen" cause="missing">
				// Doxygen is not able to create whole path recursively (like mkidr -p does) and quits with error, so let's create it for him.
				if (!File.exists(outputDir)) {
					console.info("Creating directory " + outputDir)
					File.makePath(outputDir)
				}
//</workaround>
				var f = new TextFile(product.sourceDirectory + "/cutehmi.doxygen.Doxyfile", TextFile.WriteOnly);
				try {
					f.writeLine("# This file has been autogenerated by Qbs cutehmi.doxygen module.")
					for (var option in doxygenOptions) {
						var val = doxygenOptions[option]

						if (typeof val === 'string')
							val = '"' + val + '"'
						else if (typeof val === 'boolean') {
							if (val)
								val = 'YES'
							else
								val = 'NO'
						}

						if (Array.isArray(val)) {
							for (var i = 0; i < val.length; i++)
								f.writeLine(option + ' += "' + val[i] + '"')
						} else if (val !== undefined)
							f.writeLine(option + ' = ' + val)
					}

					// Append cppreference.com '.tags' file to TAGFILES.
					f.writeLine('TAGFILES += ' + FileInfo.relativePath(product.sourceDirectory, project.sourceDirectory) + 'doc/tags/cppreference.com/cppreference-doxygen-web.tag.xml=https://en.cppreference.com/w')

					// Append Qt '.tags' files to TAGILES.
					for (var qtSubmodule in product.Qt) {
						var docSubmoduleName = 'qt' + qtSubmodule;	// Names of Qt modules in 'C:/Qt/Docs' directory start with 'qt' prefix (this applies to directories and '.tags' files).
						f.writeLine('TAGFILES += ' + product.Qt.core.docPath + '/' + docSubmoduleName + '/' + docSubmoduleName + '.tags'
									+ '=http://doc.qt.io/qt-' + product.Qt.core.versionMajor)
					}

					// Append '.tags' files to TAGFILES from dependencies.
					for (i in product.dependencies) {
						var dependency = product.dependencies[i]
						if ('cutehmi' in dependency && 'doxygen' in dependency.cutehmi) {
//<workaround id="qbs-cutehmi-doxygen-2" target="Doxygen" cause="missing">
							// To make relative links work properly first directory of the product location has to be stripped (e.g., 'cutehmi_1' instead of 'modules/cutehmi_1').
							var dependencyOutputDir = docDir + '/' + FileInfo.relativePath(project.sourceDirectory, dependency.sourceDirectory).split('/').slice(1).join('/') // Absolute.
							// Instead of:
							// var dependencyOutputDir = docDir + '/' + FileInfo.relativePath(project.sourceDirectory, dependency.sourceDirectory).split('/') // Absolute.
//</workaround>
							var tagLoc = FileInfo.relativePath(product.sourceDirectory, dependency.sourceDirectory) + '/doxygen.tag'
							var htmlLoc = FileInfo.relativePath(outputDir, dependencyOutputDir)
							f.writeLine('TAGFILES += ' + '"' +  tagLoc + ' = ' + htmlLoc + '"')
						}
					}
				} finally {
					f.close()
				}
			}

			if (!product.cutehmi.doxygen.generateRedirectionFile)
				return [doxCmd]
			else {
				var indexCmd = new JavaScriptCommand();
				indexCmd.description = 'generating ' + product.sourceDirectory + '/index.html'
				indexCmd.highlight = 'codegen';
				indexCmd.sourceCode = function() {
					var docDir = project.sourceDirectory + '/doc/Doxygen/docs'
//<workaround id="qbs-cutehmi-doxygen-2" target="Doxygen" cause="missing">
					// To make relative links work properly first directory of the product location has to be stripped (e.g., 'cutehmi_1' instead of 'modules/cutehmi_1').
					var outputDir = docDir +  '/' + FileInfo.relativePath(project.sourceDirectory, product.sourceDirectory).split('/').slice(1).join('/') // Absolute.
					// Instead of:
					// var outputDir = docDir +  '/' + FileInfo.relativePath(project.sourceDirectory, product.sourceDirectory) // Absolute.
//</workaround>
					var href = FileInfo.relativePath(product.sourceDirectory, outputDir) + '/index.html'
					var f = new TextFile(product.sourceDirectory + "/index.html", TextFile.WriteOnly);
					try {
						f.writeLine('<!DOCTYPE html>')
						f.writeLine('<!-- This file has been autogenerated by Qbs cutehmi.doxygen module. -->')
						f.writeLine('<html lang="en">')
						f.writeLine('  <head>')
						f.writeLine('    <meta http-equiv="refresh" content="0; URL=\'' + href + '\'" />')
						f.writeLine('    <meta charset="utf-8">')
						f.writeLine('    <title>Redirecting to documentation</title>')
						f.writeLine('  </head>')
						f.writeLine('  <body>')
						f.writeLine('     If you haven\'t been redirected automatically click the following <a href="' + href + '">link</a>.')
						f.writeLine('  </body>')
						f.writeLine('</html>')
					} finally {
						f.close()
					}
				}
				return [doxCmd, indexCmd]
			}
		}

		outputArtifacts: product.cutehmi.doxygen.generateRedirectionFile ? [{ filePath: product.sourceDirectory + '/cutehmi.doxygen.Doxyfile', fileTags: ["Doxyfile"] },
																			{ filePath: product.sourceDirectory + '/index.html', fileTags: ["html"] }]
																		 : [{ filePath: product.sourceDirectory + '/cutehmi.doxygen.Doxyfile', fileTags: ["Doxyfile"] }]
		outputFileTags: ["Doxyfile", "html"]
	}
}

//(c)MP: Copyright © 2019, Michal Policht <michpolicht@gmail.com>. All rights reserved.
//(c)MP: This file is a part of CuteHMI.
//(c)MP: CuteHMI is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
//(c)MP: CuteHMI is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more details.
//(c)MP: You should have received a copy of the GNU Lesser General Public License along with CuteHMI.  If not, see <https://www.gnu.org/licenses/>.
