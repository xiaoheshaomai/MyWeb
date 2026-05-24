# Morning60s: A Photo-Verified, Reward-Collecting Micro-Challenge for Getting Out of Bed

*Anonymous Author(s) — Anonymous Institution*
*Submission: ACM Creativity & Cognition 2026 — Posters Track (≤3000 words, single-column, anonymized)*

---

## Abstract

Waking up is a daily behavior that many people want to improve, yet most "alarm" solutions focus on forcing attention rather than supporting follow-through. We present **Morning60s**, a mobile app that reframes getting out of bed as a *short, playful micro-challenge*: users press "I'm up," complete a brief countdown while leaving the bed, then *prove they are standing* by taking a photo that is checked by a vision model. When verified, users receive a *collectible minimalist breakfast illustration* and a *streak calendar stamp*. Morning60s combines (1) a time-bounded challenge, (2) anti-cheating verification grounded in visual evidence, and (3) a lightweight, aesthetically cohesive reward system designed for long-term attachment. We describe the interaction flow, design rationale, and implementation, and discuss how creative, collectible rewards can make mundane self-regulation tasks feel like a meaningful ritual.

**Keywords.** Wake-up; habit formation; anti-cheating; computer vision; rewards; behavior change; playful interaction; collectibles; streaks.

---

## 1. Introduction

"Waking up" is not a single action but a sequence: noticing the moment, resisting the impulse to remain in bed, and transitioning into upright movement. Many tools intervene at the first step (alarms), yet failure often happens later — people dismiss alarms and drift back into bed. Morning60s targets this gap by focusing on one concrete outcome: *getting physically out of bed and standing*.

We explore a simple proposition: if we can make "standing up" feel like a short, game-like ritual with a satisfying collectible payoff, users may be more willing to complete the transition. However, such an app must also manage an immediate tension: *users can cheat* (e.g., tapping through screens while staying in bed). Morning60s therefore combines a playful challenge with *photo verification* to meaningfully raise the cost of cheating and to shift the experience from "checking a box" to "performing a small proof."

Our contribution is a design and implementation of an end-to-end wake-up micro-challenge that uses vision-based verification and a collectible reward economy, plus reflections on how creative output (illustrated breakfasts) can be used as a motivational scaffold for everyday behavior change.

---

## 2. System Overview

Morning60s is an iOS app that displays different "home" experiences based on system time:

- **Morning wake window (05:00–user wake-end):** a "Wake up" start screen leading into the challenge.
- **Daytime (after wake-end until 18:00):** a day recap scene.
- **Night (18:00–05:00):** a night recap scene.

This time-based structure makes the app feel context-aware: the interface becomes part of a daily rhythm instead of a generic utility.

### 2.1 Interaction Flow (Wake Ritual)

1. **Wake screen.** One large call-to-action button invites action ("Yes, I'm up").
2. **Micro-challenge.** A short countdown (e.g., five minutes) encourages leaving the bed while the UI presents a central, breathing button and an animated progress ring.
3. **Photo verification.** The user takes a photo; a vision model checks a narrow constraint: *a person standing with legs visible and floor context* — evidence of being out of bed.
4. **Reward reveal.** Successful verification triggers a celebratory card: a collectible breakfast illustration in a minimal geometric style.
5. **Calendar stamp.** The day is marked in a streak calendar with an animated "stamp" interaction.

If verification fails, the system provides a retry path, including an option to submit a higher-quality image and/or use a stronger model configuration.

### 2.2 Why Photo Verification?

Many behavior-change tools rely on self-report ("I did it"). Morning60s takes a different stance: *the app asks for a tiny piece of evidence* aligned with the target behavior. This is not surveillance; it is a design choice to (a) reduce effortless cheating, and (b) turn completion into a small performative act that feels more real than tapping a checkbox.

The verification prompt is intentionally narrow: it checks *standing up* rather than attempting to infer complex activities. The goal is to keep the ritual short, legible, and repeatable.

---

## 3. Design Rationale

### 3.1 Make the task small and finishable

The app frames success as a single, finishable unit: "stand up and prove it." The micro-challenge structure reduces ambiguity and creates a clear end state. A short countdown provides gentle, time-bounded pressure rather than punishment.

### 3.2 Make the reward aesthetically collectible

Instead of points or generic badges, Morning60s gives a *collectible illustrated breakfast*. The illustrations share a consistent minimalist geometric style to support "collection desire." The reward card is presented with a clean layout and a dramatic reveal, emphasizing that the user has *earned an object*, not just a score.

This leverages creative media as motivation: the reward is not only symbolic but also visually enjoyable and identity-reinforcing ("I'm the kind of person who collects these").

### 3.3 Make cheating meaningfully harder, not impossible

Behavior tools often fail when users can complete them without doing the behavior. Morning60s uses visual verification to raise friction for cheating. It does not claim perfect enforcement; rather, it shifts the experience so that cheating requires extra effort (e.g., staging a standing photo). In everyday practice, this can be "good enough" to support honest follow-through.

---

## 4. Implementation

Morning60s is implemented in SwiftUI. Key components include:

- **Time-based routing.** The app selects wake/day/night experiences based on system time, with minute-level refresh.
- **Challenge timer.** A periodic timeline updates the countdown and progress visuals.
- **Photo capture.** A simple camera interface collects an image for verification.
- **Vision verification.** The app sends a compressed image to either (a) a configured backend endpoint, or (b) a direct API-based model, and receives a boolean pass/fail.
- **Reward and streak persistence.** Completion is stored locally; a calendar view renders a grid for the current month and stamps completed dates. A "newly completed" flag triggers a one-time stamp animation.

The verification output is deliberately simple (pass/fail). This keeps feedback immediate and reduces the temptation to negotiate with the system. When verification fails, the UI offers a higher-quality retry flow to address false negatives.

---

## 5. Discussion: Creativity as a Motivation Scaffold

Morning60s is not only a productivity utility; it is an experiment in using *creative collectibles* to make everyday self-regulation feel meaningful. In many habit tools, rewards are abstract. Here, the reward is a designed artifact with aesthetic value. This aligns with C&C's interest in how creative processes and interactive systems can support change: the app's "change mechanism" is partly psychological (a ritual), partly technical (verification), and partly cultural (collecting and taste).

We also observe a shift in user framing: once the action is tied to a collectible, "getting up" becomes a way to obtain (and later browse) a curated gallery. The app can thus function as a personal archive of effort — each stamp and illustration is a small proof of a day started.

---

## 6. Limitations and Future Work

**Verification robustness.** A simple pose constraint can produce false negatives (lighting, framing) and cannot fully prevent determined cheating. Future work could explore multimodal checks (e.g., motion sensors) while preserving privacy and low friction.

**Personalization of wake windows.** Users have different schedules; the system currently uses a configurable wake-end time and a fixed early boundary. Future work could support adaptive windows and weekends while avoiding complexity that undermines ritual consistency.

**Longitudinal impact.** The system is designed for daily repetition, but we have not yet conducted a long-term field study. Future work should evaluate retention, user experience, and whether collectible aesthetics meaningfully affect follow-through.

---

## 7. Ethics and Privacy

Morning60s asks users to take a photo as evidence of standing. This introduces privacy concerns. The system can be configured to send images to a trusted backend; a privacy-first deployment should minimize retention, avoid storing images by default, and clearly communicate what is transmitted and why. A future version should provide on-device verification when feasible, and explicit controls for data handling.

---

## 8. Conclusion

Morning60s reframes waking up as a short, verifiable, rewarding ritual: a micro-challenge completed by leaving bed, taking a proof photo, and receiving a collectible breakfast illustration plus a calendar stamp. By combining *creative rewards* with *vision-based anti-cheating*, the app explores how aesthetic collectibles can motivate mundane behaviors and how lightweight verification can support honest follow-through. We invite discussion on designing "proof-based" micro-rituals and on the role of creative artifacts in behavior change systems.

---

## References

1. B. J. Fogg. 2009. A Behavior Model for Persuasive Design. In *Proc. Persuasive '09*.
2. P. Lally, C. H. M. van Jaarsveld, H. W. W. Potts, and J. Wardle. 2010. How are habits formed: Modelling habit formation in the real world. *European Journal of Social Psychology* 40, 6.
3. S. Deterding, D. Dixon, R. Khaled, and L. Nacke. 2011. From Game Design Elements to Gamefulness: Defining "Gamification". In *Proc. MindTrek '11*.
4. D. Kahneman. 2011. *Thinking, Fast and Slow*. Farrar, Straus and Giroux.
