#!/usr/bin/env python3
"""Generate the provisional A4 document templates bundled by the iOS app."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase.pdfmetrics import stringWidth
from reportlab.pdfgen import canvas
from reportlab.platypus import (
    KeepTogether,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_CONTENT = ROOT / "docs/legal/document-template-content.json"
DEFAULT_STRINGS = ROOT / "docs/legal/DocumentTemplates.xcstrings"
DEFAULT_OUTPUT = ROOT / "FranAlonso/Resources/DocumentTemplates"

INK = colors.HexColor("#1C1C1E")
SECONDARY_INK = colors.HexColor("#66666B")
BRAND = colors.HexColor("#7B2F70")
BRAND_SOFT = colors.HexColor("#F3E6F0")
GOLD = colors.HexColor("#D6A84B")
LINE = colors.HexColor("#D1D1D6")
SURFACE = colors.HexColor("#F7F8FA")
WARNING = colors.HexColor("#825500")
WARNING_FILL = colors.HexColor("#FFF3D6")


class InvariantCanvas(canvas.Canvas):
    """Use stable PDF metadata and object identifiers across regenerations."""

    def __init__(self, *args: Any, **kwargs: Any) -> None:
        kwargs["invariant"] = 1
        super().__init__(*args, **kwargs)


def load_content(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as source:
        return json.load(source)


def load_strings(path: Path, language: str) -> dict[str, str]:
    with path.open(encoding="utf-8") as source:
        catalog = json.load(source)

    strings: dict[str, str] = {}
    for key, entry in catalog["strings"].items():
        if not entry.get("comment"):
            raise ValueError(f"Missing translator comment for {key!r}")
        localization = entry.get("localizations", {}).get(language)
        if localization is None:
            raise ValueError(f"Missing {language!r} localization for {key!r}")
        string_unit = localization["stringUnit"]
        if string_unit.get("state") != "translated" or not string_unit.get("value"):
            raise ValueError(f"Incomplete {language!r} localization for {key!r}")
        strings[key] = string_unit["value"]
    return strings


def set_metadata(
    pdf: canvas.Canvas,
    title: str,
    author: str,
    subject: str,
) -> None:
    pdf.setTitle(title)
    pdf.setAuthor(author)
    pdf.setSubject(subject)
    pdf.setCreator("FranAlonso document template generator")


def draw_wordmark(
    pdf: canvas.Canvas,
    trade_name: str,
    x: float,
    y: float,
    scale: float = 1.0,
) -> None:
    """Draw a replaceable, vector-only provisional wordmark from its identity source."""
    words = trade_name.upper().split()
    if len(words) != 3:
        raise ValueError("The provisional wordmark expects a three-word trade name")
    first_name, last_name, descriptor_text = words

    pdf.saveState()
    pdf.setFillColor(INK)
    pdf.setStrokeColor(INK)
    pdf.setLineWidth(0.8 * scale)
    pdf.setFont("Helvetica", 18 * scale)
    pdf.drawString(x, y, first_name)
    pdf.line(x + 1 * scale, y - 3 * scale, x + 72 * scale, y - 3 * scale)
    pdf.setFont("Helvetica", 18 * scale)
    pdf.drawString(x + 22 * scale, y - 21 * scale, last_name)
    descriptor = pdf.beginText(x + 72 * scale, y - 1 * scale)
    descriptor.setFont("Helvetica", 5.6 * scale)
    descriptor.setCharSpace(1.1 * scale)
    descriptor.textOut(descriptor_text)
    pdf.drawText(descriptor)
    pdf.restoreState()


def draw_draft_badge(pdf: canvas.Canvas, text: str, x: float, y: float) -> None:
    width = stringWidth(text, "Helvetica-Bold", 6.3) + 12
    pdf.setFillColor(WARNING_FILL)
    pdf.setStrokeColor(GOLD)
    pdf.roundRect(x - width, y - 9, width, 14, 4, fill=1, stroke=1)
    pdf.setFillColor(WARNING)
    pdf.setFont("Helvetica-Bold", 6.3)
    pdf.drawCentredString(x - width / 2, y - 4, text)


def draw_contact_block(
    pdf: canvas.Canvas,
    business: dict[str, str],
    strings: dict[str, str],
    x: float,
    y: float,
) -> None:
    pdf.setFillColor(INK)
    pdf.setFont("Helvetica-Bold", 8)
    pdf.drawRightString(x, y, business["tradeName"])
    pdf.setFont("Helvetica", 7.2)
    lines = [
        (
            f"{business['legalName']} · "
            f"{strings[business['taxIdentifierLabelKey']]} "
            f"{business['taxIdentifier']}"
        ),
        business["address"],
        business["phones"],
        business["email"],
    ]
    for index, line in enumerate(lines, start=1):
        pdf.drawRightString(x, y - index * 10, line)


def consent_page_header(
    pdf: canvas.Canvas,
    document: SimpleDocTemplate,
    content: dict[str, Any],
    strings: dict[str, str],
) -> None:
    business = content["business"]
    set_metadata(
        pdf,
        strings[content["consent"]["titleKey"]],
        business["tradeName"],
        f"{strings[content['reviewStatusKey']]} · {content['documentVersion']}",
    )
    draw_wordmark(
        pdf,
        business["tradeName"],
        document.leftMargin,
        A4[1] - 42,
    )
    draw_draft_badge(
        pdf,
        strings[content["reviewStatusKey"]],
        A4[0] - document.rightMargin,
        A4[1] - 35,
    )
    pdf.setStrokeColor(GOLD)
    pdf.setLineWidth(1)
    pdf.line(
        document.leftMargin,
        A4[1] - 74,
        A4[0] - document.rightMargin,
        A4[1] - 74,
    )
    pdf.setFillColor(SECONDARY_INK)
    pdf.setFont("Helvetica", 6.5)
    pdf.drawString(document.leftMargin, 24, business["tradeName"])
    pdf.drawRightString(
        A4[0] - document.rightMargin,
        24,
        f"{content['documentVersion']} · {strings['document.page.label']} {document.page}",
    )


def build_consent_template(
    content: dict[str, Any],
    strings: dict[str, str],
    output: Path,
) -> None:
    consent = content["consent"]
    document = SimpleDocTemplate(
        str(output),
        pagesize=A4,
        leftMargin=14 * mm,
        rightMargin=14 * mm,
        topMargin=31 * mm,
        bottomMargin=14 * mm,
        title=strings[consent["titleKey"]],
        author=content["business"]["tradeName"],
        subject=strings[content["reviewStatusKey"]],
    )
    base_styles = getSampleStyleSheet()
    title_style = ParagraphStyle(
        "ConsentTitle",
        parent=base_styles["Title"],
        fontName="Helvetica-Bold",
        fontSize=13,
        leading=15,
        textColor=INK,
        alignment=TA_LEFT,
        spaceAfter=5,
    )
    intro_style = ParagraphStyle(
        "ConsentIntro",
        parent=base_styles["BodyText"],
        fontName="Helvetica",
        fontSize=7.4,
        leading=9.1,
        textColor=INK,
        spaceAfter=5,
    )
    section_style = ParagraphStyle(
        "ConsentSection",
        parent=base_styles["Heading2"],
        fontName="Helvetica-Bold",
        fontSize=8.2,
        leading=10,
        textColor=BRAND,
        spaceBefore=3,
        spaceAfter=2,
    )
    body_style = ParagraphStyle(
        "ConsentBody",
        parent=base_styles["BodyText"],
        fontName="Helvetica",
        fontSize=6.7,
        leading=8.25,
        textColor=INK,
        spaceAfter=2,
    )
    label_style = ParagraphStyle(
        "ConsentLabel",
        parent=body_style,
        fontName="Helvetica-Bold",
        textColor=BRAND,
    )
    small_style = ParagraphStyle(
        "ConsentSmall",
        parent=body_style,
        fontSize=6.2,
        leading=7.6,
        textColor=SECONDARY_INK,
    )

    story: list[Any] = [
        Paragraph(strings[consent["titleKey"]], title_style),
        Paragraph(strings[consent["introductionKey"]], intro_style),
        Paragraph(strings["consent.section.basic"], section_style),
    ]

    summary_rows = [
        [
            Paragraph(strings[item["labelKey"]], label_style),
            Paragraph(strings[item["textKey"]], body_style),
        ]
        for item in consent["summary"]
    ]
    summary = Table(summary_rows, colWidths=[31 * mm, 136 * mm], hAlign="LEFT")
    summary.setStyle(
        TableStyle(
            [
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("BACKGROUND", (0, 0), (0, -1), BRAND_SOFT),
                ("BACKGROUND", (1, 0), (1, -1), SURFACE),
                ("GRID", (0, 0), (-1, -1), 0.35, LINE),
                ("LEFTPADDING", (0, 0), (-1, -1), 5),
                ("RIGHTPADDING", (0, 0), (-1, -1), 5),
                ("TOPPADDING", (0, 0), (-1, -1), 3),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
            ]
        )
    )
    story.extend(
        [
            summary,
            Spacer(1, 4),
            Paragraph(strings["consent.section.additional"], section_style),
        ]
    )

    for detail in consent["details"]:
        story.append(
            KeepTogether(
                [
                    Paragraph(strings[detail["headingKey"]], label_style),
                    Paragraph(strings[detail["textKey"]], body_style),
                ]
            )
        )

    story.append(
        Paragraph(strings["consent.section.optional_consents"], section_style)
    )
    for option_key in consent["optionalConsents"]:
        checkbox = Table(
            [["", Paragraph(strings[option_key], body_style)]],
            colWidths=[5 * mm, 162 * mm],
            hAlign="LEFT",
        )
        checkbox.setStyle(
            TableStyle(
                [
                    ("BOX", (0, 0), (0, 0), 0.8, INK),
                    ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                    ("LEFTPADDING", (0, 0), (0, 0), 0),
                    ("RIGHTPADDING", (0, 0), (0, 0), 0),
                    ("TOPPADDING", (0, 0), (0, 0), 0),
                    ("BOTTOMPADDING", (0, 0), (0, 0), 0),
                    ("LEFTPADDING", (1, 0), (1, 0), 5),
                    ("RIGHTPADDING", (1, 0), (1, 0), 0),
                    ("TOPPADDING", (1, 0), (1, 0), 1),
                    ("BOTTOMPADDING", (1, 0), (1, 0), 2),
                ]
            )
        )
        story.extend([checkbox, Spacer(1, 3)])

    story.extend(
        [
            Paragraph(strings[consent["signatureNoticeKey"]], small_style),
            Spacer(1, 5),
        ]
    )
    signature_rows = [
        [
            strings["consent.field.client_name"],
            strings["consent.field.client_identifier"],
            strings["document.field.date"],
        ],
        ["", "", ""],
        [strings["consent.field.client_signature"], "", ""],
        ["", "", ""],
    ]
    signature_table = Table(
        signature_rows,
        colWidths=[82 * mm, 45 * mm, 40 * mm],
        rowHeights=[10, 18, 10, 27],
        hAlign="LEFT",
    )
    signature_table.setStyle(
        TableStyle(
            [
                ("SPAN", (0, 2), (-1, 2)),
                ("SPAN", (0, 3), (-1, 3)),
                ("GRID", (0, 0), (-1, 1), 0.35, LINE),
                ("BOX", (0, 2), (-1, 3), 0.35, LINE),
                ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                ("FONTNAME", (0, 2), (-1, 2), "Helvetica-Bold"),
                ("FONTSIZE", (0, 0), (-1, -1), 6.3),
                ("TEXTCOLOR", (0, 0), (-1, -1), SECONDARY_INK),
                ("BACKGROUND", (0, 0), (-1, 0), SURFACE),
                ("BACKGROUND", (0, 2), (-1, 2), SURFACE),
                ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                ("LEFTPADDING", (0, 0), (-1, -1), 4),
            ]
        )
    )
    story.append(signature_table)

    document.build(
        story,
        onFirstPage=lambda pdf, doc: consent_page_header(pdf, doc, content, strings),
        onLaterPages=lambda pdf, doc: consent_page_header(pdf, doc, content, strings),
        canvasmaker=InvariantCanvas,
    )


def draw_document_frame(
    pdf: canvas.Canvas,
    content: dict[str, Any],
    strings: dict[str, str],
    title_key: str,
    metadata_title_key: str,
) -> None:
    business = content["business"]
    set_metadata(
        pdf,
        strings[metadata_title_key],
        business["tradeName"],
        f"{strings[content['reviewStatusKey']]} · {content['documentVersion']}",
    )
    draw_wordmark(pdf, business["tradeName"], 38, A4[1] - 48, 1.15)
    draw_contact_block(pdf, business, strings, A4[0] - 38, A4[1] - 40)
    draw_draft_badge(
        pdf,
        strings["document.template.provisional_badge"],
        A4[0] - 38,
        A4[1] - 100,
    )
    pdf.setStrokeColor(GOLD)
    pdf.setLineWidth(1)
    pdf.line(38, A4[1] - 112, A4[0] - 38, A4[1] - 112)
    pdf.setFillColor(INK)
    pdf.setFont("Helvetica-Bold", 22)
    pdf.drawString(38, A4[1] - 148, strings[title_key])
    pdf.setFont("Helvetica", 7)
    pdf.setFillColor(SECONDARY_INK)
    pdf.drawRightString(A4[0] - 38, 26, business["website"])
    pdf.drawString(38, 26, content["documentVersion"])


def draw_labeled_line(
    pdf: canvas.Canvas,
    label: str,
    x: float,
    y: float,
    width: float,
) -> None:
    pdf.setFont("Helvetica-Bold", 7)
    pdf.setFillColor(SECONDARY_INK)
    pdf.drawString(x, y + 5, label)
    pdf.setStrokeColor(LINE)
    pdf.setLineWidth(0.5)
    pdf.line(x, y, x + width, y)


def draw_table_grid(
    pdf: canvas.Canvas,
    x: float,
    top: float,
    widths: list[float],
    row_height: float,
    rows: int,
    headers: list[str],
) -> float:
    total_width = sum(widths)
    bottom = top - row_height * rows
    pdf.setFillColor(SURFACE)
    pdf.rect(x, top - row_height, total_width, row_height, fill=1, stroke=0)
    pdf.setStrokeColor(LINE)
    pdf.setLineWidth(0.5)
    pdf.rect(x, bottom, total_width, row_height * rows, fill=0, stroke=1)
    cursor = x
    for width in widths[:-1]:
        cursor += width
        pdf.line(cursor, bottom, cursor, top)
    for row in range(1, rows):
        line_y = top - row_height * row
        pdf.line(x, line_y, x + total_width, line_y)
    pdf.setFillColor(INK)
    pdf.setFont("Helvetica-Bold", 7)
    cursor = x
    for header, width in zip(headers, widths):
        pdf.drawCentredString(cursor + width / 2, top - row_height + 6, header)
        cursor += width
    return bottom


def build_ticket_template(
    content: dict[str, Any],
    strings: dict[str, str],
    output: Path,
) -> None:
    pdf = InvariantCanvas(str(output), pagesize=A4, pageCompression=1)
    draw_document_frame(
        pdf,
        content,
        strings,
        "ticket.title",
        "ticket.metadata.title",
    )
    draw_labeled_line(pdf, strings["ticket.field.number"], 38, 660, 145)
    draw_labeled_line(pdf, strings["document.field.date"], 205, 660, 145)
    draw_labeled_line(pdf, strings["ticket.field.client"], 38, 624, 312)
    draw_labeled_line(pdf, strings["ticket.field.tax_identifier"], 372, 624, 185)

    bottom = draw_table_grid(
        pdf,
        x=38,
        top=588,
        widths=[44, 345, 80, 88],
        row_height=25,
        rows=12,
        headers=[
            strings["ticket.table.quantity"],
            strings["ticket.table.concept"],
            strings["table.vat"],
            strings["table.amount"],
        ],
    )
    totals = [
        strings["document.total.taxable_base"],
        strings["document.total.vat"],
        strings["document.total.total"],
    ]
    y = bottom - 24
    for label in totals:
        pdf.setFont(
            "Helvetica-Bold"
            if label == strings["document.total.total"]
            else "Helvetica",
            8,
        )
        pdf.setFillColor(INK)
        pdf.drawRightString(465, y, label)
        pdf.setStrokeColor(LINE)
        pdf.line(475, y - 2, 557, y - 2)
        y -= 22

    pdf.setFont("Helvetica-Bold", 7)
    pdf.setFillColor(SECONDARY_INK)
    pdf.drawString(38, 170, strings["document.signature.optional"])
    pdf.setStrokeColor(LINE)
    pdf.roundRect(38, 62, 220, 96, 4, fill=0, stroke=1)
    pdf.setFont("Helvetica", 6.5)
    pdf.drawString(284, 70, strings["ticket.footer.tax_included"])
    pdf.showPage()
    pdf.save()


def build_invoice_template(
    content: dict[str, Any],
    strings: dict[str, str],
    output: Path,
) -> None:
    pdf = InvariantCanvas(str(output), pagesize=A4, pageCompression=1)
    draw_document_frame(
        pdf,
        content,
        strings,
        "invoice.title",
        "invoice.metadata.title",
    )
    draw_labeled_line(pdf, strings["invoice.field.number"], 38, 660, 145)
    draw_labeled_line(pdf, strings["document.field.date"], 205, 660, 145)

    pdf.setFont("Helvetica-Bold", 8)
    pdf.setFillColor(BRAND)
    pdf.drawString(38, 632, strings["invoice.client.section"])
    draw_labeled_line(pdf, strings["invoice.client.name"], 38, 608, 312)
    draw_labeled_line(
        pdf,
        strings["invoice.client.tax_identifier"],
        372,
        608,
        185,
    )
    draw_labeled_line(pdf, strings["invoice.client.address"], 38, 574, 519)
    draw_labeled_line(
        pdf,
        strings["invoice.client.postal_city"],
        38,
        540,
        252,
    )
    draw_labeled_line(
        pdf,
        strings["invoice.client.province_country"],
        312,
        540,
        245,
    )

    bottom = draw_table_grid(
        pdf,
        x=38,
        top=506,
        widths=[35, 265, 68, 54, 55, 80],
        row_height=24,
        rows=10,
        headers=[
            strings["invoice.table.quantity"],
            strings["invoice.table.description"],
            strings["invoice.table.unit_price"],
            strings["invoice.table.discount"],
            strings["table.vat"],
            strings["table.amount"],
        ],
    )
    totals = [
        strings["document.total.taxable_base"],
        strings["invoice.total.discount"],
        strings["document.total.vat"],
        strings["document.total.total"],
    ]
    y = bottom - 24
    for label in totals:
        pdf.setFont(
            "Helvetica-Bold"
            if label == strings["document.total.total"]
            else "Helvetica",
            8,
        )
        pdf.setFillColor(INK)
        pdf.drawRightString(465, y, label)
        pdf.setStrokeColor(LINE)
        pdf.line(475, y - 2, 557, y - 2)
        y -= 20

    pdf.setFont("Helvetica-Bold", 7)
    pdf.setFillColor(SECONDARY_INK)
    pdf.drawString(38, 152, strings["document.signature.optional"])
    pdf.setStrokeColor(LINE)
    pdf.roundRect(38, 62, 220, 78, 4, fill=0, stroke=1)
    pdf.setFont("Helvetica", 6.5)
    pdf.drawString(284, 70, strings["invoice.footer.currency"])
    pdf.showPage()
    pdf.save()


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--content", type=Path, default=DEFAULT_CONTENT)
    parser.add_argument("--strings", type=Path, default=DEFAULT_STRINGS)
    parser.add_argument("--language", default="es")
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT)
    return parser.parse_args()


def main() -> None:
    arguments = parse_arguments()
    content = load_content(arguments.content)
    strings = load_strings(arguments.strings, arguments.language)
    arguments.output_dir.mkdir(parents=True, exist_ok=True)
    build_consent_template(
        content,
        strings,
        arguments.output_dir / "client-consent-template.pdf",
    )
    build_ticket_template(
        content,
        strings,
        arguments.output_dir / "billing-ticket-a4-template.pdf",
    )
    build_invoice_template(
        content,
        strings,
        arguments.output_dir / "billing-invoice-a4-template.pdf",
    )


if __name__ == "__main__":
    main()
