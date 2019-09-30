#!/bin/bash
cd ${BUILD_BASE_PATH}/${BUILD_DIR}/${REPO_TO_BUILD}
./gradlew projects | grep -o "Project ':.*'" | grep -o "CRPL.*" | cut -d"'" -f1
