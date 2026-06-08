from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.form import Form
from app.models.response import Response
from reportlab.lib.pagesizes import letter
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle
from reportlab.lib import colors
import openpyxl
import os

router = APIRouter()

@router.get("/{form_id}/excel")
def export_responses_excel(form_id: str, db: Session = Depends(get_db)):
    # 1. Verify the form exists
    form = db.query(Form).filter(Form.id == form_id).first()
    if not form:
        raise HTTPException(status_code=404, detail="Form not found")

    
    responses = db.query(Response).filter(Response.form_id == form_id).all()
    
    
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
            
            row.append(r.response_data.get(label, ""))
        ws.append(row)

    
    file_path = f"export_{form_id}.xlsx"
    wb.save(file_path)

    
    return FileResponse(
        path=file_path, 
        filename=f"{form.title}_Responses.xlsx", 
        media_type='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    )
@router.get("/{form_id}/pdf")
def export_responses_pdf(form_id: str, db: Session = Depends(get_db)):
    print("🚦 1. API Route hit successfully")
    
    form = db.query(Form).filter(Form.id == form_id).first()
    if not form:
        raise HTTPException(status_code=404, detail="Form not found")

    responses = db.query(Response).filter(Response.form_id == form_id).all()
    print(f"✅ 2. Fetched form and {len(responses)} responses")

    file_path = f"export_{form_id}.pdf"
    doc = SimpleDocTemplate(file_path, pagesize=letter)
    elements = []

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
        
    print("✅ 3. Table data mapped successfully")

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
    
    elements.append(t)
    
    print("⏳ 4. Attempting to build the PDF file... (If it freezes, it stops here)")
    doc.build(elements)
    print("✅ 5. PDF built successfully!")

    return FileResponse(
        path=file_path, 
        filename=f"{form.title}_Responses.pdf", 
        media_type='application/pdf'
    )