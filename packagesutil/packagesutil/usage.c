/*
 Copyright (c) 2012-2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#include "usage.h"
#include <stdio.h>
#include <stdlib.h>

void usage_get_project(void)
{
	(void)fprintf(stderr, "%s\n","packagesutil get project: Get value of attribute of a project\n"
				  "Usage: packagesutil --file <path> get project <attribute>\n"
				  "<attribute> is one of the following:\n"
				  "build-folder\t\tbuild-format\n"
				  "certificate-keychain\tcertificate-identity\n"
				  "name\n"
				  "Usage: packagesutil ... get project build-folder [path|path-type]\n"
				  "Usage: packagesutil ... get project build-format\n"
				  "Usage: packagesutil ... get certificate-keychain\n"
				  "Usage: packagesutil ... get certificate-identity\n"
				  "Usage: packagesutil ... get project name\n"
				  "Usage: packagesutil ... get project packages count\n"
				  "Usage: packagesutil ... get project packages list\n"
				  );
}

void usage_get_package(void)
{
	(void)fprintf(stderr, "%s\n","packagesutil get package: Get value of attribute of a package\n"
				  "Usage: packagesutil --file <path> get package[-<index>| <identifier>] <attribute>\n"
				  "<attribute> is one of the following:\n"
				  "follow-symbolic-links\t\tidentifier\n"
				  "location-path\t\t\tlocation-type\n"
				  "name\t\t\t\toverwrite-directory-permission\n"
				  "post-installation-behavior\tpost-installation-script\n"
				  "pre-installation-script\t\trelocatable\n"
				  "require-admin-password\t\tuse-hfs-compression\n"
				  "version\n\n"
				  "Usage: packagesutil ... get package[-<index>| <identifier>] follow-symbolic-links\n"
				  "Usage: packagesutil ... get package[-<index>| <identifier>] identifier\n"
				  "Usage: packagesutil ... get package[-<index>| <identifier>] location-path\n"
				  "Usage: packagesutil ... get package[-<index>| <identifier>] location-type\n"
				  "Usage: packagesutil ... get package[-<index>| <identifier>] name\n"
				  "Usage: packagesutil ... get package[-<index>| <identifier>] overwrite-directory-permission\n"
				  "Usage: packagesutil ... get package[-<index>| <identifier>] post-installation-behavior\n"
				  "Usage: packagesutil ... get package[-<index>| <identifier>] pre-installation-script path\n"
				  "Usage: packagesutil ... get package[-<index>| <identifier>] pre-installation-script path-type\n"
				  "Usage: packagesutil ... get package[-<index>| <identifier>] post-installation-script path\n"
				  "Usage: packagesutil ... get package[-<index>| <identifier>] post-installation-script path-type\n"
				  "Usage: packagesutil ... get package[-<index>| <identifier>] relocatable\n"
				  "Usage: packagesutil ... get package[-<index>| <identifier>] require-admin-password\n"
				  "Usage: packagesutil ... get package[-<index>| <identifier>] use-hfs-compression\n"
				  "Usage: packagesutil ... get package[-<index>| <identifier>] version\n"
				  );
}

void usage_get(void)
{
	(void)fprintf(stderr, "%s\n","packagesutil get: Get value of attribute of a project or package\n"
				  "Usage: packagesutil --file <path> get <object> <attribute>\n"
				  "<object> is one of the following:\n"
				  "project\npackage-<index>\npackage <identifier>\n\n"
				  "Usage: packagesutil ... get project <attribute>\n"
				  "Usage: packagesutil get project --help\n"
				  "Usage: packagesutil ... get package-<index> <attribute>\n"
				  "Usage: packagesutil ... get package <identifier> <attribute>\n"
				  "Usage: packagesutil get package --help\n"
				  );
}

void usage_set_project(void)
{
	(void)fprintf(stderr, "%s\n","packagesutil set project: Set value of attribute of a project\n"
				  "Usage: packagesutil --file <path> set project <attribute> <value>\n"
				  "<attribute> is one of the following:\n"
				  "build-folder\t\tbuild-format\n"
				  "certificate-keychain\tcertificate-identity\n"
				  "name\n"
				  "Usage: packagesutil ... set project build-folder path <string>\n"
				  "Usage: packagesutil ... set project build-folder path-type <absolute|relative|reference-folder>\n"
				  "Usage: packagesutil ... set project build-format flat|bundle\n"
				  "Usage: packagesutil ... set certificate-keychain <string>\n"
				  "Usage: packagesutil ... set certificate-identity <string>\n"
				  "Usage: packagesutil ... set project name <string>\n"
				  );
}

void usage_set_package(void)
{
	(void)fprintf(stderr, "%s\n","packagesutil set package: Set value of attribute of a package\n"
				  "Usage: packagesutil --file <path> set package[-<index>| <identifier>] <attribute> <value>\n"
				  "<attribute> is one of the following:\n"
				  "follow-symbolic-links\t\tidentifier\n"
				  "location-path\t\t\tlocation-type\n"
				  "name\t\t\t\toverwrite-directory-permission\n"
				  "post-installation-behavior\tpost-installation-script\n"
				  "pre-installation-script\t\trelocatable\n"
				  "require-admin-password\t\tuse-hfs-compression\n"
				  "version\n\n"
				  "Usage: packagesutil ... set package[-<index>| <identifier>] follow-symbolic-links <yes|no>\n"
				  "Usage: packagesutil ... set package[-<index>| <identifier>] identifier <string>\n"
				  "Usage: packagesutil ... set package[-<index>| <identifier>] location-path <string>\n"
				  "Usage: packagesutil ... set package[-<index>| <identifier>] location-type <embedded|http-url|removable-media|custom>\n"
				  "Usage: packagesutil ... set package[-<index>| <identifier>] name <string>\n"
				  "Usage: packagesutil ... set package[-<index>| <identifier>] overwrite-directory-permission <yes|no>\n"
				  "Usage: packagesutil ... set package[-<index>| <identifier>] post-installation-behavior <do-nothing|require-restart|require-shutdown|require-logout>\n"
				  "Usage: packagesutil ... set package[-<index>| <identifier>] pre-installation-script path <string>\n"
				  "Usage: packagesutil ... set package[-<index>| <identifier>] pre-installation-script path-type <absolute|relative|reference-folder>\n"
				  "Usage: packagesutil ... set package[-<index>| <identifier>] post-installation-script path <string>\n"
				  "Usage: packagesutil ... set package[-<index>| <identifier>] post-installation-script path-type <absolute|relative|reference-folder>\n"
				  "Usage: packagesutil ... set package[-<index>| <identifier>] relocatable <yes|no>\n"
				  "Usage: packagesutil ... set package[-<index>| <identifier>] require-admin-password <yes|no>\n"
				  "Usage: packagesutil ... set package[-<index>| <identifier>] use-hfs-compression <yes|no>\n"
				  "Usage: packagesutil ... set package[-<index>| <identifier>] version <string>\n"
				  );
}

void usage_set(void)
{
	(void)fprintf(stderr, "%s\n","packagesutil set: Set value of attribute of a project or package\n"
				  "Usage: packagesutil --file <path> set <object> <attribute> <value>\n"
				  "<object> is one of the following:\n"
				  "project\npackage-<index>\npackage <identifier>\n\n"
				  "Usage: packagesutil ... set project <attribute> <value>\n"
				  "Usage: packagesutil set project --help\n"
				  "Usage: packagesutil ... set package-<index> <attribute> <value>\n"
				  "Usage: packagesutil ... set package <identifier> <attribute> <value>\n"
				  "Usage: packagesutil set package --help\n"
				  );
}

void usage(void)
{
	(void)fprintf(stderr, "%s\n","Usage: packagesutil <verb> <options>\n"
				  "<verb> is one of the following:\n"
				  "get\nset\nversion\n\n"
				  "Usage: packagesutil --file <path> get [options]\n"
				  "Usage: packagesutil get --help\n"
				  "Usage: packagesutil --help\n"
				  "Usage: packagesutil --file <path> set [options]\n"
				  "Usage: packagesutil set --help\n"
				  "Usage: packagesutil version\n");
}

