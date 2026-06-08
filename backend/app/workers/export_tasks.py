from app.workers.celery_worker import celery_app
from app.core.database import SessionLocal
from app.models.form import Form
from app.models.form_response import FormResponse
import openpyxl
from reportlab.lib.pagesizes import letter
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle
from reportlab.lib import colors

@celery_app.task(name="generate_excel_export")
def generate_excel_export(form_id: str):
    db = SessionLocal()
    try:
        form = db.query(Form).filter(Form.id == form_id).first()
        responses = db.query(FormResponse).filter(FormResponse.form_id == form_id).all()
        
        wb = openpyxl.Workbook()
        ws = wb.active
        ws.title = "Form Responses"

        headers = ["Response ID", "Submitted At"]
        for field in form.schema_data.get("fields", []):
            headers.append(field.get("label"))
        ws.append(headers)

        for r in responses:
            row = [str(r.id), r.submitted_at.strftime("%Y-%m-%d %H:%M:%S")]
            for field in form.schema_data.get("fields", []):
                label = field.get("label")
                row.append(str(r.response_data.get(label, "")))
            ws.append(row)

        file_path = f"export_{form_id}.xlsx"
        wb.save(file_path)
        return file_path
    finally:
        db.close()

@celery_app.task(name="generate_pdf_export")
def generate_pdf_export(form_id: str):
    db = SessionLocal()
    try:
        form = db.query(Form).filter(Form.id == form_id).first()
        responses = db.query(FormResponse).filter(FormResponse.form_id == form_id).all()

        file_path = f"export_{form_id}.pdf"
        doc = SimpleDocTemplate(file_path, pagesize=letter)
        
        headers = ["ID (Short)", "Date"]
        for field in form.schema_data.get("fields", []):
            headers.append(field.get("label"))
        
        data = [headers]
        for r in responses:
            row = [str(r.id)[:8] + "...", r.submitted_at.strftime("%Y-%m-%d")]
            for field in form.schema_data.get("fields", []):
                label = field.get("label")
                row.append(str(r.response_data.get(label, "")).strip())
            data.append(row)

        t = Table(data)
        t.setStyle(TableStyle([
            ('BACKGROUND', (0,0), (-1,0), colors.darkgrey),
            ('TEXTCOLOR', (0,0), (-1,0), colors.whitesmoke),
            ('ALIGN', (0,0), (-1,-1), 'CENTER'),
            ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
            ('BOTTOMPADDING', (0,0), (-1,0), 12),
            ('BACKGROUND', (0,1), (-1,-1), colors.beige),
            ('GRID', (0,0), (-1,-1), 1, colors.black)
        ]))
        
        doc.build([t])
        return file_path
    finally:
        db.close()