BASE = ~/lab
SOURCE = $(BASE)/cassandra
CORE = $(SOURCE)/trunk
THRIFT = $(SOURCE)/thrift

clean:
	sudo rm -rf build
	rm -rf _trial_temp cassandra.log
	find . -name "*.pyc" -exec rm -rfv {} \;

testing-deps:
	sudo apt-get install -y ant default-jdk python-nose libtool bison flex

cassandra-base: $(BASE)
	mkdir -p $(BASE)

$(CORE): cassandra-base
	-git clone http://git-wip-us.apache.org/repos/asf/cassandra.git $(CORE)
	cd $(CORE)/pylib && sudo python setup.py install

$(THRIFT): cassandra-base
	-git clone git://git.apache.org/thrift.git $(THRIFT)
	cd $(THRIFT) && ./bootstrap.sh && ./configure && make && sudo make install 
	cd $(THRIFT)/lib/py && sudo python setup.py install

cassandra-build: cassandra-source
	cd $(CORE) && ant gen-thrift-py
	cd $(CORE) && ant clean build

check-cassanova:
	touch $(CORE)/test/__init__.py
#	PYTHONPATH=$(CORE)/test nosetests --tests=telephus.testing.testsuite
	PYTHONPATH=$(CORE)/test nosetests -x --tests=telephus.testing.cassanova.testsuite
	rm $(CORE)/test/__init__.py

check: MOD ?= "telephus"
check:
	trial $(MOD)

check-full: testing-deps $(CORE) $(THRIFT) cassandra-build check-cassanova check
.PHONY: check-full

run-fake-cassandra: stop-cassandra
	./bin/cassandra
	tail -f cassandra.log

stop-fake-cassandra:
	kill `cat cassandra.pid`

run-cassandra:
	sudo /etc/init.d/cassandra start

stop-cassandra: stop-fake-cassandra
	sudo /etc/init.d/cassandra stop
