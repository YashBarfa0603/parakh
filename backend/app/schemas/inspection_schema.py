
#Pydantic Schemas for Inspection API Requests and Responses.

from __future__ import annotations


from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel


class BatchRequest(BaseModel):
    batch_number: Optional[str] = None
    manufacturing_date: Optional[datetime] = None
    expiry_date: Optional[datetime] = None
    best_before: Optional[str] = None


class CreateInspectionRequest(BaseModel):
    commodity_category: Optional[str] = None


class DeclarationItemSchema(BaseModel):
    id: Optional[int] = None
    field_name: str
    value: Optional[str] = None
    raw_value: Optional[str] = None
    confidence: Optional[float] = None
    extraction_method: Optional[str] = "MANUAL_OVERRIDE"
    status: Optional[str] = "VERIFIED"


class UpdateDeclarationsRequest(BaseModel):
    declarations: List[DeclarationItemSchema]


class SetDecisionRequest(BaseModel):
    decision: str  # "PASS", "FAIL", "REVIEW"
    remarks: Optional[str] = None


class FinalizeInspectionRequest(BaseModel):
    decision: Optional[str] = None  # "PASS", "FAIL", "REVIEW"
    remarks: Optional[str] = None


class FinalizeInspectionResponse(BaseModel):
    message: str
    inspection_id: int
    canonical_hash: str
    status: str
    finalized_at: str
    report_id: int
    report_url: str