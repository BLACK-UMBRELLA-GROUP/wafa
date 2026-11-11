#!/usr/bin/env python3
"""Check the checked-in iOS icon and launch screen against LOCK 6."""

import json
from pathlib import Path
import plistlib
import struct
import unittest
import xml.etree.ElementTree as ET


RUNNER = Path(__file__).resolve().parents[1] / "ios" / "Runner"
CATALOG = RUNNER / "Assets.xcassets"
LAUNCH_MARK = "LaunchImage"
LAUNCH_SIZE = 132
PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
APP_ICON_SCALES = {
    "iphone": {"20": (2, 3), "29": (1, 2, 3), "40": (2, 3), "60": (2, 3)},
    "ipad": {"20": (1, 2), "29": (1, 2), "40": (1, 2), "76": (1, 2), "83.5": (2,)},
    "ios-marketing": {"1024": (1,)},
}


def catalog_images(directory):
    return json.loads((directory / "Contents.json").read_text(encoding="utf-8"))["images"]


def png_properties(path):
    """Read the dimensions and transparency metadata from a PNG."""
    data = path.read_bytes()
    if (
        len(data) < 33
        or not data.startswith(PNG_SIGNATURE)
        or struct.unpack_from(">I4s", data, 8) != (13, b"IHDR")
    ):
        raise ValueError(f"{path.name}: missing PNG header")

    width, height, _, color_type = struct.unpack_from(">IIBB", data, 16)
    chunks = set()
    offset = len(PNG_SIGNATURE)
    while offset + 12 <= len(data):
        length, kind = struct.unpack_from(">I4s", data, offset)
        offset += 12 + length  # Length, type, data and CRC.
        if offset > len(data):
            break
        chunks.add(kind)
        if kind == b"IEND":
            if b"IDAT" in chunks:
                return (width, height), color_type in (4, 6) or b"tRNS" in chunks
            break
    raise ValueError(f"{path.name}: missing complete PNG image data")


class IOSBrandAssetsTests(unittest.TestCase):
    def check_png(self, directory, image, size, *, has_alpha):
        filename = image["filename"]
        self.assertEqual(Path(filename).name, filename, "Use a file in the asset set")
        self.assertEqual(Path(filename).suffix.lower(), ".png")
        dimensions, transparency = png_properties(directory / filename)
        self.assertEqual(dimensions, (size, size), filename)
        self.assertEqual(transparency, has_alpha, f"{filename}: PNG transparency")

    def test_app_icon_slots_reference_opaque_pngs_at_their_pixel_sizes(self):
        directory = CATALOG / "AppIcon.appiconset"
        images = catalog_images(directory)
        expected = {
            (idiom, f"{size}x{size}", f"{scale}x"): int(float(size) * scale)
            for idiom, sizes in APP_ICON_SCALES.items()
            for size, scales in sizes.items()
            for scale in scales
        }
        slots = [(image["idiom"], image["size"], image["scale"]) for image in images]
        self.assertCountEqual(slots, expected.keys())
        for image, slot in zip(images, slots):
            with self.subTest(slot=slot):
                self.check_png(directory, image, expected[slot], has_alpha=False)

    def test_launch_image_scales_reference_pngs_with_transparency(self):
        directory = CATALOG / f"{LAUNCH_MARK}.imageset"
        images = catalog_images(directory)
        sizes = {f"{scale}x": LAUNCH_SIZE * scale for scale in (1, 2, 3)}
        self.assertCountEqual([image["scale"] for image in images], sizes.keys())
        for image in images:
            with self.subTest(scale=image["scale"]):
                self.assertEqual(image["idiom"], "universal")
                self.check_png(directory, image, sizes[image["scale"]], has_alpha=True)

    def test_launch_storyboard_centers_the_mark_on_locked_green(self):
        storyboard = ET.parse(RUNNER / "Base.lproj" / "LaunchScreen.storyboard").getroot()
        self.assertEqual(storyboard.get("launchScreen"), "YES")
        self.assertEqual(storyboard.get("useAutolayout"), "YES")
        controller_id = storyboard.attrib["initialViewController"]
        view = storyboard.find(
            f"./scenes/scene/objects/viewController[@id='{controller_id}']/view[@key='view']"
        )
        self.assertIsNotNone(view, "Launch controller needs a root view")
        mark = view.find(f"./subviews/imageView[@image='{LAUNCH_MARK}']")
        self.assertIsNotNone(mark, "Launch view needs the LaunchImage asset")
        self.assertEqual(mark.get("contentMode"), "center")
        self.assertEqual(mark.get("translatesAutoresizingMaskIntoConstraints"), "NO")

        image = storyboard.find(f"./resources/image[@name='{LAUNCH_MARK}']")
        self.assertIsNotNone(image, "LaunchImage needs a storyboard resource entry")
        for dimension in ("width", "height"):
            self.assertEqual(float(image.attrib[dimension]), LAUNCH_SIZE, dimension)

        constraints = view.findall("./constraints/constraint")
        view_id, mark_id = view.attrib["id"], mark.attrib["id"]
        for axis in ("centerX", "centerY"):
            centered = [
                constraint for constraint in constraints
                if {constraint.get("firstItem"), constraint.get("secondItem")}
                == {view_id, mark_id}
                and constraint.get("firstAttribute") == axis
                and constraint.get("secondAttribute") == axis
            ]
            self.assertEqual(len(centered), 1, f"LaunchImage needs one {axis} constraint")
            constraint = centered[0]
            self.assertEqual(constraint.get("relation", "equal"), "equal", axis)
            self.assertEqual(float(constraint.get("constant", "0")), 0, axis)
            self.assertEqual(float(constraint.get("multiplier", "1")), 1, axis)

        # The PNG provides the intrinsic size. Any explicit size must agree.
        for owner in (view, mark):
            for constraint in owner.findall("./constraints/constraint"):
                dimension = constraint.get("firstAttribute")
                if (
                    constraint.get("firstItem", owner.attrib["id"]) == mark_id
                    and dimension in ("width", "height")
                ):
                    self.assertIsNone(constraint.get("secondItem"), dimension)
                    self.assertEqual(constraint.get("relation", "equal"), "equal", dimension)
                    self.assertEqual(float(constraint.get("constant", "0")), LAUNCH_SIZE, dimension)

        background = view.find("./color[@key='backgroundColor']")
        self.assertIsNotNone(background, "Launch view needs a background color")
        self.assertEqual(background.get("customColorSpace"), "sRGB")
        for component, value in (("red", 0x12), ("green", 0x3F), ("blue", 0x32), ("alpha", 255)):
            self.assertAlmostEqual(float(background.attrib[component]), value / 255, places=6)

    def test_plist_sets_a_visible_light_launch_status_bar(self):
        with (RUNNER / "Info.plist").open("rb") as file:
            plist = plistlib.load(file)
        self.assertEqual(plist["UILaunchStoryboardName"], "LaunchScreen")
        self.assertEqual(plist["UIStatusBarStyle"], "UIStatusBarStyleLightContent")
        self.assertIs(plist.get("UIStatusBarHidden", False), False)
        self.assertIs(plist.get("UIViewControllerBasedStatusBarAppearance", True), True)


if __name__ == "__main__":
    unittest.main()
