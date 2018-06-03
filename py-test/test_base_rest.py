import unittest
import requests
import uuid


def get_name():
    return str(uuid.uuid4()) + "@spawn.com"


class SgClient:

    def __init__(self):
        self.endpoint = "http://localhost:8010"
        self.token = ""

    def register(self, user, psw):
        request = {
            "username": user,
            "password": psw
        }

        resp = requests.put(self.endpoint + '/auth/register', json=request)

        if resp.status_code != 200:
            return resp.text
        else:
            json = resp.json()
            self.token = json["token"]
            return None

    def login(self, user, psw):
        request = {
            "username": user,
            "password": psw
        }

        resp = requests.post(self.endpoint + '/auth/login', json=request)

        if resp.status_code != 200:
            return resp.text
        else:
            json = resp.json()
            self.token = json["token"]
            return None

    def whoami(self):
        resp = requests.get(self.endpoint + '/whoami', headers={"Authorization": self.token})
        if resp.status_code != 200:
            return True, resp.text
        else:
            return False, resp.json()

    def get_profile(self):
        resp = requests.get(self.endpoint + '/profile', headers={"Authorization": self.token})

        if resp.status_code != 200:
            return True, resp.text
        else:
            return False, resp.json()

    def update_profile(self, first_name, last_name, country):
        json = {"personal": {"firstName": first_name, "lastName": last_name}, "country": country}
        resp = requests.post(self.endpoint + '/profile', headers={"Authorization": self.token}, json=json)
        if resp.status_code != 200:
            return resp.text
        else:
            return None

    def logout(self):
        resp = requests.post(self.endpoint + '/logout', headers={"Authorization": self.token})
        if resp.status_code != 200:
            return resp.text
        else:
            return None

    def delete_profile(self):
        resp = requests.delete(self.endpoint + '/profile', headers={"Authorization": self.token})
        if resp.status_code != 200:
            return resp.text
        else:
            return None


class TestSimpleRest(unittest.TestCase):

    def testRegister(self):
        api = SgClient()

        err = api.register(get_name(), "password")

        self.assertIsNone(err)
        self.assertTrue(len(api.token) > 0)

    def testAlreadyRegistered(self):
        api = SgClient()
        name = get_name()

        err = api.register(name, "password")
        self.assertIsNone(err)

        err = api.register(name, "password")
        self.assertIsNotNone(err)

        se = "Error: AppLogicError, alreadyRegistered({})".format(name)
        self.assertEqual(se, str(err))

    def testLogin(self):
        name = get_name()

        api1 = SgClient()
        err = api1.register(name, "password")
        self.assertIsNone(err)

        api2 = SgClient()
        err = api2.login(name, "password")
        self.assertIsNone(err)

        self.assertNotEqual(api1.token, api2.token)

    def testWhoami(self):
        name = get_name()

        api = SgClient()
        err = api.register(name, "password")
        self.assertIsNone(err)

        is_err, json = api.whoami()
        self.assertFalse(is_err)

        self.assertEqual(name, json["username"])

    def testGetProfile(self):
        name = get_name()

        api = SgClient()
        err = api.register(name, "password")
        self.assertIsNone(err)

        is_err, json = api.get_profile()
        self.assertFalse(is_err)

        self.assertEqual("UA", json["country"])
        self.assertEqual("", json["personal"]["firstName"])
        self.assertEqual("", json["personal"]["lastName"])

    def testUpdateProfile(self):
        name = get_name()

        api = SgClient()
        err = api.register(name, "password")
        self.assertIsNone(err)

        err = api.update_profile("vasya", "pupkin", "US")
        self.assertIsNone(err)

        is_err, json = api.get_profile()
        self.assertFalse(is_err)

        self.assertEqual("US", json["country"])
        self.assertEqual("vasya", json["personal"]["firstName"])
        self.assertEqual("pupkin", json["personal"]["lastName"])

    def testLogout(self):
        name = get_name()

        api = SgClient()
        err = api.register(name, "password")
        self.assertIsNone(err)

        err = api.logout()
        self.assertIsNone(err)

        is_err, err = api.whoami()
        self.assertTrue(is_err)
        self.assertEqual("Error: AppLogicError, tokenNotFound", str(err))

    def testDeleteProfile(self):
        name = get_name()

        api1 = SgClient()
        err = api1.register(name, "password")
        self.assertIsNone(err)

        err = api1.delete_profile()
        self.assertIsNone(err)

        api2 = SgClient()
        err = api2.login(name, "password")
        self.assertIsNotNone(err)

        se = "Error: AppLogicError, userNotFound({})".format(name)
        self.assertEqual(se, str(err))


if __name__ == '__main__':
    unittest.main()
