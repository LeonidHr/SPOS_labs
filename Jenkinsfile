pipeline {
    agent { label 'built-in' }

    environment {
        PACKAGE_NAME = 'count-files'
        PACKAGE_VERSION = '2.0'
        PACKAGE_RELEASE = "${BUILD_NUMBER}"
        FULL_VERSION = "${PACKAGE_VERSION}-${BUILD_NUMBER}"
        REPO_DIR = '/var/jenkins_home/repo'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                sh 'ls -la'
                script {
                    currentBuild.displayName = "#${BUILD_NUMBER} v${FULL_VERSION}"
                }
            }
        }

        stage('ShellCheck') {
            agent {
                docker {
                    image 'koalaman/shellcheck-alpine:stable'
                    args '--entrypoint='
                    reuseNode true
                }
            }
            steps {
                sh 'shellcheck --version'
                sh 'shellcheck -f gcc count_files.sh > shellcheck-report.txt || true'
                sh 'cat shellcheck-report.txt'
                sh 'shellcheck -S error count_files.sh'
            }
        }

        stage('Test Script') {
            steps {
                sh 'chmod +x count_files.sh'
                sh 'bash -n count_files.sh'
                sh './count_files.sh'
            }
        }

        stage('Build Packages') {
            failFast true
            parallel {
                stage('Build RPM') {
                    agent {
                        docker {
                            image 'fedora:latest'
                            args '-u root'
                            reuseNode true
                        }
                    }
                    steps {
                        sh '''
                            dnf install -y rpm-build rpmdevtools
                            rpmdev-setuptree
                            mkdir -p ~/rpmbuild/SOURCES/${PACKAGE_NAME}-${PACKAGE_VERSION}
                            cp count_files.sh count-files.conf count_files.1 ~/rpmbuild/SOURCES/${PACKAGE_NAME}-${PACKAGE_VERSION}/
                            cd ~/rpmbuild/SOURCES
                            tar czvf ${PACKAGE_NAME}-${PACKAGE_VERSION}.tar.gz ${PACKAGE_NAME}-${PACKAGE_VERSION}
                            cp ${WORKSPACE}/packaging/rpm/count-files.spec ~/rpmbuild/SPECS/
                            sed -i -e "s/^Version:.*/Version:        ${PACKAGE_VERSION}/" \
                                   -e "s/^Release:.*/Release:        ${PACKAGE_RELEASE}%{?dist}/" \
                                   ~/rpmbuild/SPECS/count-files.spec
                            rpmbuild -ba ~/rpmbuild/SPECS/count-files.spec
                            cp ~/rpmbuild/RPMS/noarch/*.rpm ${WORKSPACE}/
                            chown -R 1000:1000 ${WORKSPACE}
                        '''
                    }
                }

                stage('Build DEB') {
                    agent {
                        docker {
                            image 'ubuntu:latest'
                            args '-u root'
                            reuseNode true
                        }
                    }
                    environment {
                        DEBIAN_FRONTEND = 'noninteractive'
                    }
                    steps {
                        sh '''
                            apt-get update
                            apt-get install -y build-essential debhelper
                            mkdir -p build/${PACKAGE_NAME}-${PACKAGE_VERSION}
                            cp count_files.sh count-files.conf build/${PACKAGE_NAME}-${PACKAGE_VERSION}/
                            cp -r packaging/deb/debian build/${PACKAGE_NAME}-${PACKAGE_VERSION}/
                            cd build/${PACKAGE_NAME}-${PACKAGE_VERSION}
                            sed -i "1s/([^)]*)/(${FULL_VERSION})/" debian/changelog
                            dpkg-buildpackage -us -uc -b
                            cp ../*.deb ${WORKSPACE}/
                            chown -R 1000:1000 ${WORKSPACE}
                        '''
                    }
                }
            }
        }

        stage('Test Packages') {
            parallel {
                stage('Test RPM Installation') {
                    agent {
                        docker {
                            image 'oraclelinux:8'
                            args '-u root'
                            reuseNode true
                        }
                    }
                    steps {
                        sh '''
                            rpm -ivh ${PACKAGE_NAME}-*.rpm
                            count_files
                            rpm -e ${PACKAGE_NAME}
                        '''
                    }
                }

                stage('Test DEB Installation') {
                    agent {
                        docker {
                            image 'ubuntu:latest'
                            args '-u root'
                            reuseNode true
                        }
                    }
                    steps {
                        sh '''
                            dpkg -i ${PACKAGE_NAME}_*.deb || apt-get install -f -y
                            count_files
                            apt-get remove -y ${PACKAGE_NAME}
                        '''
                    }
                }
            }
        }

        stage('Publish') {
            parallel {
                stage('Publish RPM') {
                    agent {
                        docker {
                            image 'fedora:latest'
                            args '-u root'
                            reuseNode true
                        }
                    }
                    steps {
                        sh '''
                            dnf install -y createrepo_c
                            mkdir -p ${REPO_DIR}/rpm
                            cp ${PACKAGE_NAME}-*.rpm ${REPO_DIR}/rpm/
                            createrepo_c --update ${REPO_DIR}/rpm
                            chown -R 1000:1000 ${REPO_DIR}
                        '''
                    }
                }

                stage('Publish DEB') {
                    agent {
                        docker {
                            image 'ubuntu:latest'
                            args '-u root'
                            reuseNode true
                        }
                    }
                    environment {
                        DEBIAN_FRONTEND = 'noninteractive'
                    }
                    steps {
                        sh '''
                            apt-get update
                            apt-get install -y apt-utils
                            mkdir -p ${REPO_DIR}/deb
                            cp ${PACKAGE_NAME}_*.deb ${REPO_DIR}/deb/
                            cd ${REPO_DIR}/deb
                            apt-ftparchive packages . > Packages
                            gzip -kf Packages
                            apt-ftparchive release . > Release
                            chown -R 1000:1000 ${REPO_DIR}
                        '''
                    }
                }
            }
        }

        stage('Tag Release') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'github-creds',
                                                  usernameVariable: 'GIT_USER',
                                                  passwordVariable: 'GIT_TOKEN')]) {
                    sh '''
                        git config user.name "Jenkins"
                        git config user.email "jenkins@localhost"
                        git tag -a "jenkins-v${FULL_VERSION}" -m "Jenkins build ${BUILD_NUMBER}, version ${FULL_VERSION}"
                        git push "https://${GIT_USER}:${GIT_TOKEN}@github.com/LeonidHr/SPOS_labs.git" "jenkins-v${FULL_VERSION}"
                    '''
                }
            }
        }
    }

    post {
        success {
            archiveArtifacts artifacts: '*.rpm, *.deb, shellcheck-report.txt'
            echo "Build ${FULL_VERSION} completed successfully!"
            emailext(
                to: '$DEFAULT_RECIPIENTS',
                subject: "SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER} (v${env.FULL_VERSION})",
                mimeType: 'text/html',
                body: """<p>Pipeline <b>${env.JOB_NAME}</b> #${env.BUILD_NUMBER} completed successfully.</p>
                         <p>Package version: <b>${env.FULL_VERSION}</b></p>
                         <p><a href="${env.BUILD_URL}">Build</a> | <a href="${env.BUILD_URL}artifact/">Artifacts</a></p>"""
            )
        }
        failure {
            echo 'Build failed!'
            emailext(
                to: '$DEFAULT_RECIPIENTS',
                subject: "FAILURE: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                mimeType: 'text/html',
                body: """<p>Pipeline <b>${env.JOB_NAME}</b> #${env.BUILD_NUMBER} failed.</p>
                         <p><a href="${env.BUILD_URL}console">Console Output</a></p>""",
                attachLog: true
            )
        }
        cleanup {
            cleanWs()
        }
    }
