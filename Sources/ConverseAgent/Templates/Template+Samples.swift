extension Template {
    static let samples = #"""
import Foundation

/// Values the previews draw: a conversation about a garden, its sources and a weave. The app's own values never
/// come from here.
enum ConverseSamples {
    static let exchanges: [ConverseExchange] = [
        ConverseExchange(
            id: "sample-1",
            prompt: "What should I plant along a shady fence?",
            reply: "Ferns and hostas like the shade and the damp a fence keeps, and both come back every spring without much care.\n\nFor colour, try foxgloves at the back: they grow tall, flower in early summer and **seed themselves** for the next year.",
            highlights: [
                ConverseHighlight(phrase: "Ferns and hostas like the shade", owner: "sample-you"),
                ConverseHighlight(phrase: "come back every spring", owner: "sample-you"),
                ConverseHighlight(phrase: "flower in early summer", owner: "sample-club"),
            ],
            owners: [
                ConverseOwner(id: "sample-you", name: "You", royalty: 64, mine: true, documents: [
                    ConverseDocument(id: "shade-notes-001", text: "Hostas and ferns did best along the north fence this year.", influence: 58),
                    ConverseDocument(id: "shade-notes-002", text: "Moss kept the soil under the fence damp all summer.", influence: 42),
                ]),
                ConverseOwner(id: "sample-club", name: "Garden Club", royalty: 28, groups: [
                    ConverseGroup(id: "cottage-borders", name: "Cottage Borders", summary: "Tall flowers for the back of a bed, sown once.",
                                  tags: ["flowers", "shade"], documents: [
                        ConverseDocument(id: "cottage-borders-001", text: "Foxgloves flower in early summer.", influence: 70),
                        ConverseDocument(id: "cottage-borders-002", text: "They seed themselves where the soil stays damp.", influence: 30),
                    ]),
                ]),
                ConverseOwner(id: "sample-almanac", name: "Old Almanac", royalty: 8, documents: [
                    ConverseDocument(id: "almanac-001", text: "Plant ferns when the frosts are over.", influence: 100),
                ]),
            ]
        ),
        ConverseExchange(id: "sample-2", prompt: "How often should I water them?", reply: "Once a week, deeply, unless it rains. Use `slow` drip lines in a dry spell."),
        ConverseExchange(id: "sample-3", prompt: "And in winter?"),
    ]

    static let readings: [ConverseReading] = [
        ConverseReading(word: "rooted", text: "The questions stay close to the ground: what grows where, and what it needs to keep growing."),
        ConverseReading(word: "seasonal", text: "Each answer reaches a little further into the year, from this spring toward the next."),
        ConverseReading(word: "patient", text: "Nothing here is hurried. The thread waits for the garden as much as the garden waits for it."),
    ]
}
"""#
}
