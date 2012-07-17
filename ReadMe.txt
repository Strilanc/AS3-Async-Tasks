An async library for AS3, based on .Net tasks.

---
Installation
---
Download source, copy the src/Async folder into your AS3 project

---
Testing
---
Download source, open project in FlashDevelop, run.

---
Overview
---
This library works with 'eventual results', represented by the type 'Async.Task'. Tasks are better than events because they propagate exceptions, require less cleanup, and can be linked in interesting ways.

The easiest way to get useful basic tasks is via static methods in the 'Async.TaskInterop' class (e.g. 'Delay', 'ListenForEnterFrame', 'Load', 'PlaySound', 'InvokeWebServiceMethod', ...). You can also expose existing functionality as a task by using the 'Async.TaskSource' class. For example, Async.TaskInterop.ListenForEvent works by adding an event listener that sets a TaskSource's result to the event argument.

Basic tasks are useful on their own, but the real magic is how you can chain off of them using Await/ContinueWith/Bind. For example, if you wanted to load a sequence of sounds then play them one after another:

	private function LoadPlaySoundsAsync(paths : Vector.<String>) : Task {
		// start loading sounds
		//Note: StartMany returns a task for the array of results of all the tasks created by a callback invokes on all the items in a sequence
		var loadedSoundsAsync:Task = TaskEx.StartMany(paths, TaskInterop.LoadSound);
		
		// after the sounds are loaded, play them one by one
		//Note: 'Bind' awaits its task then runs the given ASYNC callback, directly exposing its eventual result
		var allSoundsPlayedAsync:Task = loadedSoundsAsync.Bind(function(sounds:Array):Task {
			// loop over the sounds, waiting for each to play out
			var i:int = -1;
			return TaskEx.DoWhile(function():Task {
				//Note: DoWhile evaluates its callback as long as it keeps returning a true task
				// check for end of loop
				i += 1;
				if (i >= sounds.length) return TaskEx.Wrap(false);
				
				// play the current sound then continue the loop
				var sound:Sound = sounds[i];
				var playSoundAsync:Task = TaskInterop.PlaySound(sound);
				//Note: ContinueWith awaits the task then runs a given callback, exposing its eventual result as a task
				var trueAfterPlayedSoundAsync:Task = playSoundAsync.ContinueWith(function():Boolean { 
					return true; 
				});
				return trueAfterPlayedSoundAsync;
			});
		});
		
		return allSoundsPlayedAsync;
	}

I know that code seems complicated but keep in mind:

- Exceptions propagate correctly. If one of the sounds fails to load, no sound is played and the task returned from LoadPlaySoundsAsync contains an error event.
- Cancellation can be added easily. If LoadPlaySoundsAsync took a cancelation token, it could just pass it on to the interop methods and thereby be stopped at any time by canceling the token.
- The alternative is **so much worse**. I suggest you try to write it from scratch, to really see.

---
Q&A
---
**What's the difference between Await, ContinueWith and Bind?**

Await runs its callback even if the task faults, whereas ContinueWith and Bind will instead just propagate the exception without running their callbacks.

Bind unwraps its result, to help avoid tasks containing tasks. Bind(Func<Task<int>>) returns a Task<int> whereas ContinueWith(Func<Task<int>>) would return an inconvenient Task<Task<int>>.

Unfortunately, because AS3 has poor support for generics, it is not always obvious when to use bind vs continuewith. A good rule of thumb is to bind if and only if the callback returns a task.
