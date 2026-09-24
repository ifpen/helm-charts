import email
import email.policy
import importlib.util
import pathlib
import unittest


MODULE_PATH = pathlib.Path(__file__).with_name("sendmail-graph.py")
SPEC = importlib.util.spec_from_file_location("sendmail_graph", MODULE_PATH)
SENDMAIL_GRAPH = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(SENDMAIL_GRAPH)


class SendmailGraphTests(unittest.TestCase):
    def parse_message(self, raw_message):
        return email.message_from_bytes(raw_message, policy=email.policy.default)

    def test_build_message_decodes_folded_headers_and_html_body(self):
        raw_message = (
            b"From: =?UTF-8?Q?Marie_Dupont?= <marie@example.org>\r\n"
            b"To: =?UTF-8?Q?J=C3=A9r=C3=B4me?= <jerome@example.org>\r\n"
            b"Subject: =?UTF-8?Q?T=C3=A9l=C3=A9chargement?=\r\n"
            b" =?UTF-8?Q?_termin=C3=A9?=\r\n"
            b"MIME-Version: 1.0\r\n"
            b"Content-Type: multipart/alternative; boundary=\"BOUNDARY\"\r\n"
            b"\r\n"
            b"--BOUNDARY\r\n"
            b"Content-Type: text/plain; charset=\"utf-8\"\r\n"
            b"Content-Transfer-Encoding: quoted-printable\r\n"
            b"\r\n"
            b"T=C3=A9l=C3=A9chargement termin=C3=A9 en texte brut.\r\n"
            b"--BOUNDARY\r\n"
            b"Content-Type: text/html; charset=\"utf-8\"\r\n"
            b"Content-Transfer-Encoding: quoted-printable\r\n"
            b"\r\n"
            b"<html><body>T=C3=A9l=C3=A9chargement termin=C3=A9 en HTML.</body></html>\r\n"
            b"--BOUNDARY--\r\n"
        )

        payload = SENDMAIL_GRAPH.build_message(
            self.parse_message(raw_message),
            "shared@example.org",
            [],
            send_on_behalf_of=True,
        )

        message = payload["message"]
        self.assertEqual(message["subject"], "Téléchargement terminé")
        self.assertNotIn("=?UTF-8?", message["subject"])
        self.assertEqual(message["toRecipients"][0]["emailAddress"]["name"], "Jérôme")
        self.assertEqual(
            message["toRecipients"][0]["emailAddress"]["address"],
            "jerome@example.org",
        )
        self.assertEqual(message["body"]["contentType"], "HTML")
        self.assertIn("Téléchargement terminé", message["body"]["content"])
        self.assertEqual(message["from"]["emailAddress"]["name"], "Marie Dupont")
        self.assertEqual(message["from"]["emailAddress"]["address"], "marie@example.org")
        self.assertEqual(message["sender"]["emailAddress"]["address"], "shared@example.org")

    def test_build_message_supports_plain_text_messages(self):
        raw_message = (
            b"To: =?UTF-8?Q?J=C3=A9r=C3=B4me?= <jerome@example.org>\r\n"
            b"Subject: =?UTF-8?Q?T=C3=A9l=C3=A9chargement_termin=C3=A9?=\r\n"
            b"MIME-Version: 1.0\r\n"
            b"Content-Type: text/plain; charset=\"utf-8\"\r\n"
            b"Content-Transfer-Encoding: quoted-printable\r\n"
            b"\r\n"
            b"T=C3=A9l=C3=A9chargement termin=C3=A9 en texte brut.\r\n"
        )

        payload = SENDMAIL_GRAPH.build_message(
            self.parse_message(raw_message),
            "shared@example.org",
            [],
        )

        message = payload["message"]
        self.assertEqual(message["subject"], "Téléchargement terminé")
        self.assertEqual(message["body"]["contentType"], "Text")
        self.assertIn("Téléchargement terminé", message["body"]["content"])

    def test_build_message_keeps_inline_file_parts_as_attachments(self):
        raw_message = (
            b"To: Jerome <jerome@example.org>\r\n"
            b"Subject: Test inline image\r\n"
            b"MIME-Version: 1.0\r\n"
            b"Content-Type: multipart/related; boundary=\"BOUNDARY\"\r\n"
            b"\r\n"
            b"--BOUNDARY\r\n"
            b"Content-Type: text/html; charset=\"utf-8\"\r\n"
            b"Content-Transfer-Encoding: quoted-printable\r\n"
            b"\r\n"
            b"<html><img src=3D\"cid:logo\"></html>\r\n"
            b"--BOUNDARY\r\n"
            b"Content-Type: image/png\r\n"
            b"Content-Transfer-Encoding: base64\r\n"
            b"Content-Disposition: inline; filename=\"logo.png\"\r\n"
            b"Content-ID: <logo>\r\n"
            b"\r\n"
            b"iVBORw0KGgo=\r\n"
            b"--BOUNDARY--\r\n"
        )

        payload = SENDMAIL_GRAPH.build_message(
            self.parse_message(raw_message),
            "shared@example.org",
            [],
        )

        attachment = payload["message"]["attachments"][0]
        self.assertEqual(attachment["name"], "logo.png")
        self.assertTrue(attachment["isInline"])
        self.assertEqual(attachment["contentId"], "logo")


if __name__ == "__main__":
    unittest.main()
