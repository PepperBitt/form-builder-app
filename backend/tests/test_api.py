def test_health(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_signup_and_login(client):
    signup = client.post(
        "/api/auth/signup",
        json={"email": "user@example.com", "password": "secret123"},
    )
    assert signup.status_code == 201

    login = client.post(
        "/api/auth/login",
        data={"username": "user@example.com", "password": "secret123"},
    )
    assert login.status_code == 200
    assert "access_token" in login.json()


def test_form_crud(client, auth_headers):
    create = client.post(
        "/api/forms/create",
        headers=auth_headers,
        json={
            "title": "Survey",
            "fields": [{"type": "text", "label": "Name", "required": True}],
            "status": "draft",
        },
    )
    assert create.status_code == 201
    form_id = create.json()["form_id"]

    get_form = client.get(f"/api/forms/{form_id}", headers=auth_headers)
    assert get_form.status_code == 200
    assert get_form.json()["title"] == "Survey"
    assert get_form.json()["status"] == "draft"

    update = client.put(
        f"/api/forms/{form_id}",
        headers=auth_headers,
        json={"title": "Updated Survey"},
    )
    assert update.status_code == 200
    assert update.json()["title"] == "Updated Survey"

    my_forms = client.get("/api/users/me/forms", headers=auth_headers)
    assert my_forms.status_code == 200
    assert my_forms.json()["total"] == 1

    delete = client.delete(f"/api/forms/{form_id}", headers=auth_headers)
    assert delete.status_code == 200

    my_forms_after = client.get("/api/users/me/forms", headers=auth_headers)
    assert my_forms_after.json()["total"] == 0


def test_draft_and_publish(client, auth_headers):
    create = client.post(
        "/api/forms/create",
        headers=auth_headers,
        json={
            "title": "Draft Form",
            "fields": [{"type": "text", "label": "Comment", "required": False}],
        },
    )
    form_id = create.json()["form_id"]

    drafts = client.get("/api/forms/drafts", headers=auth_headers)
    assert drafts.status_code == 200
    assert drafts.json()["total"] == 1

    publish = client.post(f"/api/forms/{form_id}/publish", headers=auth_headers)
    assert publish.status_code == 200
    assert publish.json()["status"] == "published"

    public = client.get(f"/api/forms/{form_id}")
    assert public.status_code == 200

    unpublish = client.post(f"/api/forms/{form_id}/unpublish", headers=auth_headers)
    assert unpublish.status_code == 200
    assert unpublish.json()["status"] == "draft"


def test_profile_and_settings(client, auth_headers):
    profile = client.get("/api/users/profile", headers=auth_headers)
    assert profile.status_code == 200
    assert profile.json()["email"] == "test@example.com"

    update_profile = client.put(
        "/api/users/profile",
        headers=auth_headers,
        json={"full_name": "Test User"},
    )
    assert update_profile.status_code == 200
    assert update_profile.json()["full_name"] == "Test User"

    settings = client.get("/api/users/settings", headers=auth_headers)
    assert settings.status_code == 200
    assert settings.json()["theme"] == "system"

    update_settings = client.put(
        "/api/users/settings",
        headers=auth_headers,
        json={"theme": "dark", "email_notifications": False},
    )
    assert update_settings.status_code == 200
    assert update_settings.json()["theme"] == "dark"
    assert update_settings.json()["email_notifications"] is False


def test_notifications(client, auth_headers):
    create = client.post(
        "/api/forms/create",
        headers=auth_headers,
        json={
            "title": "Feedback",
            "fields": [{"type": "text", "label": "Feedback", "required": True}],
            "status": "published",
        },
    )
    form_id = create.json()["form_id"]

    submit = client.post(
        "/api/responses/submit",
        json={"form_id": form_id, "response_data": {"Feedback": "Great app"}},
    )
    assert submit.status_code == 201

    notifications = client.get("/api/notifications", headers=auth_headers)
    assert notifications.status_code == 200
    assert notifications.json()["total"] >= 1

    mark_read = client.put(
        "/api/notifications/read",
        headers=auth_headers,
        json={},
    )
    assert mark_read.status_code == 200
    assert "Marked" in mark_read.json()["message"]


def test_export_endpoints(client, auth_headers):
    create = client.post(
        "/api/forms/create",
        headers=auth_headers,
        json={
            "title": "Export Test",
            "fields": [{"type": "text", "label": "Answer", "required": True}],
            "status": "published",
        },
    )
    form_id = create.json()["form_id"]
    client.post(
        "/api/responses/submit",
        json={"form_id": form_id, "response_data": {"Answer": "Yes"}},
    )

    for path in [
        f"/api/forms/{form_id}/export/json",
        f"/api/forms/{form_id}/export/csv",
        f"/api/forms/{form_id}/export/pdf",
        f"/api/export/{form_id}/excel",
    ]:
        response = client.get(path, headers=auth_headers)
        assert response.status_code == 200
        assert response.content


def test_protected_routes_require_auth(client):
    assert client.get("/api/users/profile").status_code == 401
    assert client.get("/api/users/me/forms").status_code == 401
    assert client.get("/api/notifications").status_code == 401
