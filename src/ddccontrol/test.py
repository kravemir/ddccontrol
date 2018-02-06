import dbus
import dbusmock
import unittest
import subprocess
import sys

class TestMyProgram(dbusmock.DBusTestCase):
    @classmethod
    def setUpClass(klass):
        klass.start_system_bus()
        klass.dbus_con = klass.get_dbus(system_bus=True)

    def setUp(self):
        self.p_mock = self.spawn_server('ddccontrol.DDCControl',
                                        '/ddccontrol/DDCControl',
                                        'ddccontrol.DDCControl',
                                        system_bus=True,
                                        stdout=subprocess.PIPE)

        self.dbus_upower_mock = dbus.Interface(
                self.dbus_con.get_object('ddccontrol.DDCControl','/ddccontrol/DDCControl'),
                dbusmock.MOCK_IFACE
        )

        self.dbus_upower_mock.AddMethod('', 'OpenMonitor', 's', 'ss', "ret = ('TEST123', 'vcp()',)")
        self.dbus_upower_mock.AddMethod('', 'GetControl', 'su', 'iqq', "ret = (1, 10, 100)")

    def tearDown(self):
        self.p_mock.terminate()
        self.p_mock.wait()

    def test_valgrind_probe(self):
        execution = subprocess.run(['valgrind', '--error-exitcode=1', 'ddccontrol', '-r','16','dev:/dev/i2c-4'], stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)

        print("-- OUT --")
        print(execution.stdout)
        print("-- ERR --")
        print(execution.stderr)
        print("-- RET --")
        print(execution.returncode)


if __name__ == '__main__':
    # avoid writing to stderr
    unittest.main(testRunner=unittest.TextTestRunner(stream=sys.stdout, verbosity=2))
