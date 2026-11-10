// ---------- Catalog sent to the UI ----------

export type CameraFocus = "default" | "front" | "rear" | "side" | "wheel" | "top" | "interior";

export type BennysOption = {
    Label: string;
    Value: any;
    Price: number;
};

type BaseNode = {
    Id: string;
    Label: string;
    Description: string;
    Icon: string;
    Camera?: CameraFocus;
};

// Opens a deeper level of the items list.
export type MenuNode = BaseNode & {
    Type: "Menu";
    Children: BennysNode[];
};

// A list of parts to choose from ("Part 3 / In stock / $750").
export type OptionsNode = BaseNode & {
    Type: "Options";
    Slot: string;
    Options: BennysOption[];
};

// Colour picker. Mode "Custom" = free RGB (primary/secondary), "Index" = snapped to GTA palette, "RGB" = free RGB (neon / tyre smoke).
export type ColorNode = BaseNode & {
    Type: "Color";
    Slot: string;
    Mode: "Custom" | "Index" | "RGB";
    Price: number;
    TypeSlot?: string; // Paint type slot (Normal / Metallic / ...)
    TypePrice?: number;
};

export type SliderNode = BaseNode & {
    Type: "Slider";
    Price: number;
    Sliders: Array<{
        Slot: string;
        Label: string;
        Description: string;
        Min: number;
        Max: number;
        Step: number;
    }>;
};

// Instant cart item (e.g. repair).
export type ActionNode = BaseNode & {
    Type: "Action";
    Slot: string;
    Value: any;
    Price: number;
};

export type BennysNode = MenuNode | OptionsNode | ColorNode | SliderNode | ActionNode;

export type BennysCategory = {
    Id: string;
    Label: string;
    Description: string;
    Icon: string;
    Items: BennysNode[];
};

export type OpenPayload = {
    Header: string;
    SubHeader: string;
    Categories: BennysCategory[];
    Current: Record<string, any>; // Installed value per slot
    Palette: string[];
    PaintTypes: Array<{ Label: string; Value: number }>;
};

// ---------- Cart ----------

export type CartEntry = {
    Slot: string;
    Label: string;
    Option: string;
    Value: any;
    Price: number;
};

// Legacy (kept for the old menu helper)
export type BennysItem = {
    Id?: number;
    Label: string;
    Subtext: false | string;
    Children?: BennysItem[];
    Data: any;
}
