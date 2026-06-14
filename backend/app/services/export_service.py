import csv
import json
import os
import uuid
from typing import Any

import openpyxl
from reportlab.lib import colors
from reportlab.lib.pagesizes import letter
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle

from app.core.config import get_settings
from app.models.form import Form
from app.models.form_response import FormResponse


def _ensure_export_dir() -> str:
    settings = get_settings()
    os.makedirs(settings.EXPORT_DIR, exist_ok=True)
    return settings.EXPORT_DIR


def export_form_json(form: Form, responses: list[FormResponse]) -> str:
    export_dir = _ensure_export_dir()
    file_path = os.path.join(export_dir, f"export_{form.id}_{uuid.uuid4().hex[:8]}.json")
    payload: dict[str, Any] = {
        "form": {
            "id": form.id,
            "title": form.title,
            "description": form.description,
            "status": form.status,
            "schema": form.schema_data,
            "created_at": form.created_at.isoformat() if form.created_at else None,
            "updated_at": form.updated_at.isoformat() if form.updated_at else None,
        },
        "responses": [
            {
                "id": response.id,
                "submitted_at": response.submitted_at.isoformat()
                if response.submitted_at
                else None,
                "answers": response.response_data,
            }
            for response in responses
        ],
    }
    with open(file_path, "w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2)
    return file_path


def export_form_csv(form: Form, responses: list[FormResponse]) -> str:
    export_dir = _ensure_export_dir()
    file_path = os.path.join(export_dir, f"export_{form.id}_{uuid.uuid4().hex[:8]}.csv")
    fields = form.schema_data.get("fields", []) if form.schema_data else []
    headers = ["response_id", "submitted_at"] + [
        field.get("label", "") for field in fields
    ]
    with open(file_path, "w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(headers)
        for response in responses:
            row = [
                response.id,
                response.submitted_at.strftime("%Y-%m-%d %H:%M:%S")
                if response.submitted_at
                else "",
            ]
            for field in fields:
                label = field.get("label", "")
                row.append(response.response_data.get(label, ""))
            writer.writerow(row)
    return file_path


def export_form_pdf(form: Form, responses: list[FormResponse]) -> str:
    export_dir = _ensure_export_dir()
    file_path = os.path.join(export_dir, f"export_{form.id}_{uuid.uuid4().hex[:8]}.pdf")
    fields = form.schema_data.get("fields", []) if form.schema_data else []
    headers = ["Response ID", "Submitted At"] + [field.get("label", "") for field in fields]
    data = [headers]
    for response in responses:
        row = [
            str(response.id)[:12],
            response.submitted_at.strftime("%Y-%m-%d %H:%M:%S")
            if response.submitted_at
            else "",
        ]
        for field in fields:
            label = field.get("label", "")
            row.append(str(response.response_data.get(label, "")))
        data.append(row)
    doc = SimpleDocTemplate(file_path, pagesize=letter)
    table = Table(data)
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), colors.darkgrey),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.whitesmoke),
                ("ALIGN", (0, 0), (-1, -1), "CENTER"),
                ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                ("BOTTOMPADDING", (0, 0), (-1, 0), 12),
                ("BACKGROUND", (0, 1), (-1, -1), colors.beige),
                ("GRID", (0, 0), (-1, -1), 1, colors.black),
            ]
        )
    )
    doc.build([table])
    return file_path


def export_form_excel(form: Form, responses: list[FormResponse]) -> str:
    export_dir = _ensure_export_dir()
    file_path = os.path.join(export_dir, f"export_{form.id}_{uuid.uuid4().hex[:8]}.xlsx")
    fields = form.schema_data.get("fields", []) if form.schema_data else []
    workbook = openpyxl.Workbook()
    worksheet = workbook.active
    worksheet.title = "Form Responses"
    headers = ["Response ID", "Submitted At"] + [
        field.get("label", "") for field in fields
    ]
    worksheet.append(headers)
    for response in responses:
        row = [
            str(response.id),
            response.submitted_at.strftime("%Y-%m-%d %H:%M:%S")
            if response.submitted_at
            else "",
        ]
        for field in fields:
            label = field.get("label", "")
            row.append(response.response_data.get(label, ""))
        worksheet.append(row)
    workbook.save(file_path)
    return file_path
