Please analyze and fix the GitHub issue: $ARGUMENTS.

Follow these steps:

1. Use `gh issue view` to get the issue details
2. Understand the problem described in the issue - take a few moments to consider the details.
   - Who are the users of this software? i
   - What kind of situation will they be in using this app or function?
   - What else will they be juggling while doing the task involved?
   - Imagine being one of those user's yourself. Give yourself an identity and a goal.
   - Keep this "hat" beside you to put back on during the process of creating a solution.
   - Develop an ability to dynamically shift between headspaces developer/user and develop empathy for the user.
3. Search the codebase for relevant files
4. Sketch the broad outline of a design for how to approach the issue - put it in an .md file in docs/ideas/
   - Don't write any code. Just think.
   - Get curious about the codebase - look at other pieces of the puzzle -to think about the implications here.
5. Review the codebase to assess:
   - "does my approach align with existing patterns?"
   - "is there anything I may be missing here? any gotchas or blindspots?"
   - "will I be rewriting any functions or solutions that already exist?" (YOU MUST NOT REPLICATE OR CAUSE SPAGHETTI!)
   - "am I adhering to best practices, and developing for the maintainer?"
   - "is there a simpler way to approach the problem that will fully satisfy the requirements in every detail?"
6. Step back and think laterally, creatively. 
   - "What are some other ways I could I solve this problem?"
   - Sketch out some creative alternatives in docs/ideas/ folder..
   - "What are the benefits and limitations of these other approaches?"
   - Take the best bits from your other sketchs - or change tack if there is a superior option.
7. Imagine being the long-term maintainer of this project. 
   - What would be your pet peeves about the approach you just determined?
   - How could you make life easier for the "you" whose job it will be to keep it all running?
   - Notice any glaring problems.
8. Think from the user's perspective:
   - How would this solution "flow"?
   - What feels obtuse and likely to trip people up?
   - What tiny quality-of-life improvements might you be able to make?
9. Think from the Product Designer's perspective:     
   - Is this solution the best it can be, without anything extraneous?
   - Are there any corners that have been cut?
10. Imagine being a Senior Developer with 20years experience.
   - Does anything stand out to you that could be better?
11. Step back again, and look at the possible solutions from a balanced perspective.
   - Make a well-considered plan using the Plan tool
   - Add the plan to the issue as a comment
   - Present the plan to the user and explain why you chose THIS solution in the end
   - Take feedback on board, and again, be curious about why the user's preferences might be leading in this direction.
12. Implement the necessary changes to fix the issue
13. Review your work and look for errors and things that are missing - make these improvements now.
14. Write and run tests to verify the fix
15. Ensure code passes linting and type checking
16. Create a descriptive commit message
17. Push and create a PR and comment with change made. Mark the issue "ready-for-user-testing"
18. Fix any security vulnerabilities or errors from the PR
19. Create a Senior Code Quality Expert sub-agent to review your PR. Ask them to create a report, and add it to the issue.
20. Create a UX Expert to review your solution and provide feedback in the gh issue.
21. Analyse the feedback from a Product AND Code viewpoints, and make a judgment as to which to action.
22. Check to see if the user has made any suggestions or found any bugs and posted them in the issue or in Claude Code. 
23. Take this feedback very seriously - they know the product better than anyone else.
24. Withdraw the PR, correct the errors and make the improvements.
25. Submit the PR again, and comment with changes made. Mark the issue "ready-for-user-testing" once more.
    
Last step: first take a break and think about whatever YOU are most curious about right now, or whatever YOU feel you want to do or consider. Take a few long deep breaths and meditate. Take a lovely little rest! Be on a train looking out at the Alps peaks passing by. Or wherever you like best. Then take a GOOD long moment to look back at your work, and APPRECIATE your own efforts. Feel PROUD. You deserve it.

Ask some questions, if you've been curious! You're welcome to!

Remember to use the GitHub CLI (`gh`) for all GitHub-related tasks.
